import "@nomicfoundation/hardhat-toolbox";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import {deployContract, increaseTime, getContractAt, increaseBlock, unlockAccount, toWei} from "../../utils/testHelper";
import {getWantFromWhale} from "../../utils/setupHelper";

/*
    Test steps:
    1. Ascertain what users would have received before the exploit block (15691462) 
        - User 1 (RUGGED): 0xd2d24db10c43811302780e082a3e6f73a97ea48f
            - Gauge(0x162cEC141E6703d08B4844C9246e7AA56726E8C6).exit()
            - Jar(0x8CA1D047541FE183aE7b5d80766eC6d5cEeb942A).withdrawAll()
            - Deposits ~$40k
        - User 2: 0x53f2f84f7829e2d4f9c024f7bedb06609dab5ac5
            - Gauge(0x162cEC141E6703d08B4844C9246e7AA56726E8C6).exit()
            - Jar(0x8CA1D047541FE183aE7b5d80766eC6d5cEeb942A).withdrawAll()
            - Deposits: ~$73k

    2. Query liquidity of jar before exploit and pToken supply
        - Obtain liquidity/pToken 

    3. Determine jar remaining liquidity after User 1 burn of 0.0000714734027123 pTokens in https://etherscan.io/tx/0xc947629e86423848bf35809e655e9bd42b74202537b14f03626f646eaf104246
        - Remaining Liquidity = Liquidity Jar - Liquidity User 1 
    3a. Rug jar
    4. Determine amounts to reimburse jar based on Remaining Liquidity 
    5. Airdrop Jar
    6. Strategy(0xd33d3D71C6F710fb7A94469ED958123Ab86858b1).rebalance()
    7. Jar(0x8CA1D047541FE183aE7b5d80766eC6d5cEeb942A).earn()
    8. Impersonate User 2 and exit jar to check amounts against initial amounts
*/

describe("StrategyUsdcEthUniV3Restoration", () => {
  const CIPIO_ADDRESS = "0x000000000088E0120F9E6652CC058AeC07564F69";

  let victim, user, cipio;
  let jar, strategy, gauge, rugProxy, uniNft;
  let token0, token1;
  let token0Name, token0Decimals, token1Name, token1Decimals;
  let liquidityValue; // token value for 1e18 worth of liquidity
  let liquidityAfterVictimWithdrawal; // This is the state that we want to return the jar to

  before("Setup Contracts", async () => {
    const [alice] = await ethers.getSigners();

    const JAR_ADDRESS = "0x8CA1D047541FE183aE7b5d80766eC6d5cEeb942A";
    const GAUGE_ADDRESS = "0x162cEC141E6703d08B4844C9246e7AA56726E8C6";

    const UNI_NFT = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88";
    const VICTIM_ADDRESS = "0xd2d24db10c43811302780e082a3e6f73a97ea48f";

    const USER_ADDRESS = "0x53f2f84f7829e2d4f9c024f7bedb06609dab5ac5";

    jar = await getContractAt("src/pickle-jar-univ3.sol:PickleJarUniV3", JAR_ADDRESS);

    strategy = await getContractAt("StrategyUsdcEth05UniV3", "0x184a71185674c789b4177a49bd41a96ce2c421ef");

    gauge = await getContractAt("Gauge", GAUGE_ADDRESS);
    uniNft = await getContractAt("src/interfaces/univ3/IUniswapV3PositionsNFT.sol:IUniswapV3PositionsNFT", UNI_NFT);

    rugProxy = await deployContract("WithdrawNFT");

    victim = await unlockAccount(VICTIM_ADDRESS);
    user = await unlockAccount(USER_ADDRESS);
    cipio = await unlockAccount(CIPIO_ADDRESS);

    await alice.sendTransaction({
      to: CIPIO_ADDRESS,
      value: toWei(1),
    });

    // Token details for display
    const [token0Addr, token1Addr] = await Promise.all([jar.token0(), jar.token1()]);

    token0 = await getContractAt("src/lib/erc20.sol:ERC20", token0Addr);

    token1 = await getContractAt("src/lib/erc20.sol:ERC20", token1Addr);

    [token0Name, token0Decimals, token1Name, token1Decimals] = await Promise.all([
      token0.name(),
      token0.decimals(),
      token1.name(),
      token1.decimals(),
    ]);
  });

  it("should give a proper accounting of funds", async () => {
    console.log("\n===============State Before Exploit==============");
    const initialLiquidity = await jar.totalLiquidity();
    console.log("\nLiquidity in Jar before exploit:", initialLiquidity);

    // Tokens for 1e18 units of liquidity
    liquidityValue = await strategy.amountsForLiquid();

    const token0Before = ethers.utils.formatUnits(
      initialLiquidity.mul(liquidityValue[0]).div((1e18).toFixed()),
      token0Decimals
    );

    const token1Before = ethers.utils.formatUnits(
      initialLiquidity.mul(liquidityValue[1]).div((1e18).toFixed()),
      token1Decimals
    );

    console.log(`\nTokens in Jar before: ${token0Name} = ${token0Before}, ${token1Name} = ${token1Before}`);

    console.log("\nSimulating transations to remove victim and user liquidity...");

    await gauge.connect(victim).exit();
    await jar.connect(victim).withdrawAll();

    liquidityAfterVictimWithdrawal = await jar.totalLiquidity();

    await gauge.connect(user).exit();
    await jar.connect(user).withdrawAll();

    await logUserBalance("Victim", victim._address);
    await logUserBalance("User", user._address);

    console.log(`\nJar liquidity after victim withdrawal: ${liquidityAfterVictimWithdrawal}`);
  });

  it("should rug the NFT", async () => {
    console.log("\n===============Rugging the NFT==============");

    const WITHDRAW_SIGNATURE = "0x3ccfd60b";

    const liquidityBeforeRug = await jar.totalLiquidity();
    console.log("\nLiquidity in Jar before rug ┏༼ ◉╭╮◉༽┓ ", liquidityBeforeRug);

    console.log("\nNFT balance before rug:", await uniNft.balanceOf(CIPIO_ADDRESS));

    const tokenId = await strategy.tokenId();

    await strategy.connect(cipio).execute(rugProxy.address, WITHDRAW_SIGNATURE);

    await uniNft.connect(cipio).decreaseLiquidity({
      tokenId,
      liquidity: liquidityBeforeRug,
      amount0Min: 0,
      amount1Min: 0,
      deadline: Math.floor(Date.now() / 1000) + 900,
    });

    console.log("\nNFT balance after rug:", await uniNft.balanceOf(CIPIO_ADDRESS));

    console.log("\nLiquidity in Jar after rug ┏༼ ◉╭╮◉༽┓ ", await jar.totalLiquidity());
  });

  it("should make the jar whole", async () => {
    console.log("\n===============Undo the Rug==============");
    const token0Needed = ethers.utils.formatUnits(
      liquidityAfterVictimWithdrawal.mul(liquidityValue[0]).div((1e18).toFixed()),
      token0Decimals
    );

    const token1Needed = ethers.utils.formatUnits(
      liquidityAfterVictimWithdrawal.mul(liquidityValue[1]).div((1e18).toFixed()),
      token1Decimals
    );

    console.log(`\nTokens needed to make Jar whole: ${token0Name} = ${token0Needed}, ${token1Name} = ${token1Needed}`);

    const WHALE = "0x8EB8a3b98659Cce290402893d0123abb75E3ab28";
    await getWantFromWhale(
      token0.address,
      liquidityAfterVictimWithdrawal.mul(liquidityValue[0]).div((1e18).toFixed()),
      strategy.address,
      WHALE
    );
    await getWantFromWhale(
      token1.address,
      liquidityAfterVictimWithdrawal.mul(liquidityValue[1]).div((1e18).toFixed()),
      strategy.address,
      WHALE
    );

    console.log("\nReturning the now empty NFT to the strategy and rebalancing...");

    const tokenId = await strategy.tokenId();
    uniNft.connect(cipio).transferFrom(CIPIO_ADDRESS, strategy.address, tokenId);

    await strategy.connect(cipio).rebalance();
    console.log("rebalanced");

    console.log("\nLiquidity in Jar after restoration ٩(^‿^)۶ ", await jar.totalLiquidity());
  });

  it("should ensure that innocent User gets the same withdrawal", async () => {
    console.log("\n===============User Withdrawal==============");
  });

  const logUserBalance = async (name, userAddress) => {
    const token0Balance = await token0.balanceOf(userAddress);
    const token1Balance = await token1.balanceOf(userAddress);

    console.log(
      `\n${name} Balance: ${token0Name} = ${ethers.utils.formatUnits(
        token0Balance,
        token0Decimals
      )}, ${token1Name} = ${ethers.utils.formatUnits(token1Balance, token1Decimals)}`
    );
  };
});
