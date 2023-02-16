import "@nomicfoundation/hardhat-toolbox";
import {deployJarV3, deployStrategyV3, flatDeployAndVerifyContract} from "./utils";
import fetch from "cross-fetch";
import * as dotenv from "dotenv";
import {BigNumber, Contract} from "ethers";
import {ethers} from "hardhat";
dotenv.config();

interface IData {
  [chain: string]: {
    strats: {oldJarAddr: string; oldStrategyAddr: string; newStrategyContract: string}[];
    keeper: string;
    api: string;
    migrationProxy?: string;
  };
}
const data: IData = {
  ETH: {
    strats: [
      {
        oldJarAddr: "0xAaCDaAad9a9425bE2d666d08F741bE4F081C7ab1",
        oldStrategyAddr: "0xae2e6daA0FD5c098C8cE87Df573E32C9d6493384", //wbtc-eth
        newStrategyContract: "src/strategies/uniswapv3/strategy-univ3-wbtc-eth-lp.sol:StrategyWbtcEthUniV3",
      },
      {
        oldJarAddr: "0xf0Fb82757B9f8A3A3AE3524e385E2E9039633948",
        oldStrategyAddr: "0x3B63E25e9fD76F152b4a2b6DfBfC402c5ba19A01", //eth-cow
        newStrategyContract: "src/strategies/uniswapv3/strategy-univ3-eth-cow-lp.sol:StrategyEthCowUniV3",
      },
      {
        oldJarAddr: "0x49ED0e6B438430CEEdDa8C6d06B6A2797aFA81cA",
        oldStrategyAddr: "0x5e20293615A4Caa3E2a9B5D24B40DBB176Ec01a8",
        newStrategyContract: "src/strategies/uniswapv3/strategy-univ3-ape-eth-lp.sol:StrategyApeEthUniV3",
      },
      {
        oldJarAddr: "0x8CA1D047541FE183aE7b5d80766eC6d5cEeb942A",
        oldStrategyAddr: "0xd33d3D71C6F710fb7A94469ED958123Ab86858b1",
        newStrategyContract: "src/strategies/uniswapv3/strategy-univ3-usdc-eth-05-lp.sol:StrategyUsdcEth05UniV3",
      },
    ],
    keeper: "0xEb088Cb6B5EDec8BF4Ec1189b28521EE820686BF",
    api: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY_MAINNET}`,
  },
  OP: {
    strats: [
      {
        oldJarAddr: "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6",
        oldStrategyAddr: "0x754ece9AC6b3FF9aCc311261EC82Bd1B69b8E00B",
        newStrategyContract:
          "src/strategies/optimism/uniswapv3/strategy-univ3-eth-btc-lp.sol:StrategyEthBtcUniV3Optimism",
      },
      {
        oldJarAddr: "0xbE27C2415497f8ae5E6103044f460991E32636F8",
        oldStrategyAddr: "0xE9936818ecd2a6930407a11C090260b5390A954d",
        newStrategyContract:
          "src/strategies/optimism/uniswapv3/strategy-univ3-eth-dai-lp.sol:StrategyEthDaiUniV3Optimism",
      },
      {
        oldJarAddr: "0x24f8b36b7349053A33E3767bc44B8FF20813AE5e",
        oldStrategyAddr: "0x1634e17813D54Ffc7506523D6e8bf08556207468",
        newStrategyContract:
          "src/strategies/optimism/uniswapv3/strategy-univ3-eth-op-lp.sol:StrategyEthOpUniV3Optimism",
      },
      {
        oldJarAddr: "0xBBF8233867c1982D66EA920d726d24391B713550",
        oldStrategyAddr: "0x1570B5D17a0796112263F4E3FAeee53459B41A49",
        newStrategyContract:
          "src/strategies/optimism/uniswapv3/strategy-univ3-eth-usdc-lp.sol:StrategyEthUsdcUniV3Optimism",
      },
      {
        oldJarAddr: "0x37Cc6Ce6eda683AB97433f4Bf26bAbD63889df23",
        oldStrategyAddr: "0x1Bb40496D3074A2345d5e3Ac28b990854A7BDe34",
        newStrategyContract:
          "src/strategies/optimism/uniswapv3/strategy-univ3-susd-dai-lp.sol:StrategySusdDaiUniV3Optimism",
      },
      {
        oldJarAddr: "0x637Bbfa0Ba3dE1341c469B15986D4AaE2c8d3cE5",
        oldStrategyAddr: "0xa99e8a5754a53bE312Fba259c7C4619cfB00E849",
        newStrategyContract:
          "src/strategies/optimism/uniswapv3/strategy-univ3-susd-usdc-lp.sol:StrategySusdUsdcUniV3Optimism",
      },
      {
        oldJarAddr: "0xae2A28B97FFF55ca62881cBB30De0A3D9949F234",
        oldStrategyAddr: "0x387C985176A314c9e5D927a99724de98576812aF",
        newStrategyContract:
          "src/strategies/optimism/uniswapv3/strategy-univ3-usdc-dai-lp.sol:StrategyUsdcDaiUniV3Optimism",
      },
    ],
    keeper: "0xA1F13ccC3205F767cEa4F254Bb1A2B53933798b2",
    api: `https://opt-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY_OPTIMISM}`,
  },
  POLY: {
    strats: [
      {
        oldJarAddr: "0xf4b1635f6B71D7859B4184EbDB5cf7321e828055",
        oldStrategyAddr: "0xbE27C2415497f8ae5E6103044f460991E32636F8",
        newStrategyContract: "src/strategies/polygon/uniswapv3/strategy-univ3-wbtc-eth-lp.sol:StrategyWbtcEthUniV3Poly",
      },
      {
        oldJarAddr: "0x925b6f866AeB88131d159Fc790b9FC8203621B3C",
        oldStrategyAddr: "0x11b8c80F452e54ae3AB2E8ce9eF9603B0a0f56D9",
        newStrategyContract:
          "src/strategies/polygon/uniswapv3/strategy-univ3-matic-eth-lp.sol:StrategyMaticEthUniV3Poly",
      },
      {
        oldJarAddr: "0x09e4E5fc62d8ae06fD44b3527235693f29fda852",
        oldStrategyAddr: "0x293731CA8Da0cf1d6dfFB5125943F05Fe0B5fF99",
        newStrategyContract:
          "src/strategies/polygon/uniswapv3/strategy-univ3-matic-usdc-lp.sol:StrategyMaticUsdcUniV3Poly",
      },
      {
        oldJarAddr: "0x75415BF29f054Ab9047D26501Ad5ef93B5364eb0",
        oldStrategyAddr: "0xD5236f71580E951010E814118075F2Dda90254db",
        newStrategyContract: "src/strategies/polygon/uniswapv3/strategy-univ3-usdc-eth-lp.sol:StrategyUsdcEthUniV3Poly",
      },
      {
        oldJarAddr: "0x6ddCE484E929b2667C604f6867A4a7b3d344A917",
        oldStrategyAddr: "0x846d0ED75c285E6D70A925e37581D0bFf94c7651",
        newStrategyContract:
          "src/strategies/polygon/uniswapv3/strategy-univ3-usdc-usdt-lp.sol:StrategyUsdcUsdtUniV3Poly",
      },
    ],
    keeper: "0xa5F338D9a684A75C47a2caF3b104A496ec8bEad0",
    api: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY_POLYGON}`,
  },
  ARB: {
    strats: [
      {
        oldJarAddr: "0x1212DdD66C8eB227183fce794C4c13d1c5a87b88",
        oldStrategyAddr: "0x41A610baad8BfdB620Badff488A034B06B13790D", //eth-usdc
        newStrategyContract:
          "src/strategies/arbitrum/uniswapv3/strategy-univ3-eth-usdc-lp.sol:StrategyUsdcEthUniV3Arbi",
      },
      {
        oldJarAddr: "0xe5BD4954Bd6749a8E939043eEDCe4C62b41CC6D0",
        oldStrategyAddr: "0x9C485ae43280dD0375C8c2290F1f77aee17CF512", //eth-gmx
        newStrategyContract: "src/strategies/arbitrum/uniswapv3/strategy-univ3-gmx-eth-lp.sol:StrategyGmxEthUniV3Arbi",
      },
    ],
    keeper: "0xaEE8A262E3A4E89AF95BEF5F224C74159d6Fdf4d",
    api: `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY_ARBITRUM}`,
  },
};
const tsukeAddr = "0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf";

const jarSnapshot = async (jarAddr: string, chain: string) => {
  const api = data[chain].api;
  let stakingAddress: string;
  if (chain === "ETH") {
    const provider = new ethers.providers.JsonRpcProvider(api);
    const abi = ["function getGauge(address) view returns(address)"];
    const gaugeProxy = new ethers.Contract("0x2e57627ACf6c1812F99e274d0ac61B786c19E74f", abi, provider);
    stakingAddress = await gaugeProxy.getGauge(jarAddr);
  }
  const aggregatedTransfers = [];

  // Get transfers logs paginated in 1k transfers per batch
  // Alchemy rounds the values on this endpoint, so we can't use it.
  let keepPulling = true;
  let pageKey: string | undefined = undefined;
  while (keepPulling) {
    const options = {
      method: "POST",
      headers: {accept: "application/json", "content-type": "application/json"},
      body: JSON.stringify({
        id: 1,
        jsonrpc: "2.0",
        method: "alchemy_getAssetTransfers",
        params: [
          {
            fromBlock: "0x0",
            toBlock: "latest",
            contractAddresses: [jarAddr],
            category: ["erc20"],
            withMetadata: false,
            excludeZeroValue: true,
            maxCount: "0x3e8", // 1000 transfers per response
          },
        ],
      }),
    };
    if (pageKey)
      options.body = JSON.stringify({
        id: 1,
        jsonrpc: "2.0",
        method: "alchemy_getAssetTransfers",
        params: [
          {
            fromBlock: "0x0",
            toBlock: "latest",
            contractAddresses: [jarAddr],
            category: ["erc20"],
            withMetadata: false,
            excludeZeroValue: true,
            maxCount: "0x3e8", // 1000 transfers per response
            pageKey,
          },
        ],
      });

    const resp = await (await fetch(api, options)).json();
    if (resp.result.pageKey) {
      pageKey = resp.result.pageKey;
      keepPulling = true;
    } else {
      keepPulling = false;
    }
    aggregatedTransfers.push(resp.result.transfers);
  }

  // Get the actual transfers logs
  const transfers: {
    blockHash: string;
    blockNumber: string;
    transactionIndex: string;
    address: string;
    logIndex: string;
    data: string;
    removed: boolean;
    topics: string[];
    transactionHash: string;
  }[] = [];
  for (let i = 0; i < aggregatedTransfers.length; i++) {
    const transfersBatch = aggregatedTransfers[i];
    const topics = ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"]; //transfer log signature
    const fromBlock = transfersBatch[0].blockNum;
    const toBlock = transfersBatch[transfersBatch.length - 1].blockNum;

    const options = {
      method: "POST",
      headers: {accept: "application/json", "content-type": "application/json"},
      body: JSON.stringify({
        id: 1,
        jsonrpc: "2.0",
        method: "eth_getLogs",
        params: [
          {
            address: [jarAddr],
            fromBlock,
            toBlock,
            topics,
          },
        ],
      }),
    };

    const resp = await (await fetch(api, options)).json();
    transfers.push(...resp.result);
  }

  // Decode transfer logs
  const users: {[user: string]: BigNumber} = {};
  transfers.forEach((transfer) => {
    const from: string = ethers.utils.defaultAbiCoder.decode(["address"], transfer.topics[1])[0];
    const to: string = ethers.utils.defaultAbiCoder.decode(["address"], transfer.topics[2])[0];
    const value: BigNumber = ethers.utils.defaultAbiCoder.decode(["uint256"], transfer.data)[0];

    if (from === stakingAddress || to === stakingAddress) return;

    if (from === ethers.constants.AddressZero) {
      const toBalance = users[to];
      users[to] = toBalance ? toBalance.add(value) : value;
    } else if (to === ethers.constants.AddressZero) {
      const fromBalance = users[from];
      if (!fromBalance || fromBalance.sub(value).lt(BigNumber.from("0"))) {
        console.log(transfer);
        console.log("Balance before transfer: " + fromBalance);
        throw "Address transferring more than it owns!";
      }
      users[from] = fromBalance.sub(value);
    } else {
      const fromBalance = users[from];
      const toBalance = users[to];
      if (!fromBalance || fromBalance.sub(value).lt(BigNumber.from("0"))) {
        console.log(transfer);
        console.log("Balance before transfer: " + fromBalance);
        throw "Address transferring more than it owns!";
      }
      users[from] = fromBalance.sub(value);
      users[to] = toBalance ? toBalance.add(value) : value;
    }
  });

  // Cleanup users with 0 balance
  Object.keys(users).forEach((userAddr) => users[userAddr].isZero() && delete users[userAddr]);

  Object.keys(users).forEach((user) => console.log(user + ": " + users[user].toString()));

  return users;
};

const deployMigrationProxy = async () => {
  const proxyContract = "src/tmp/univ3-migration-proxy.sol:Proxy";
  const proxyAddr = await flatDeployAndVerifyContract(proxyContract, [], false, true);
  const migrationProxy = await ethers.getContractAt(proxyContract, proxyAddr);
  console.log(`✔️ Migration Proxy deployed at: ${migrationProxy.address}`);
  return migrationProxy.address;
};

// Call execute on a strategy to migration proxy
const callExecuteToProxy = async (
  executeContract: Contract,
  proxyContract: Contract,
  targetFuncName: string,
  targetFuncArgs: any[]
) => {
  const txnData = proxyContract.interface.encodeFunctionData(targetFuncName, targetFuncArgs);
  return await executeContract.execute(proxyContract.address, txnData).then((x) => x.wait());
};

const migrateV3StratAndJar1 = async (oldStrategyAddress: string, newStrategyContract: string, chain: string) => {
  const deployer = await ethers.getSigners().then((x) => x[0]);
  console.log(`Deployer: ${deployer.address}`);

  const poolAbi = ["function tickSpacing() view returns(int24)", "function fee() view returns(uint24)"];

  const oldStrategy = await ethers.getContractAt(newStrategyContract, oldStrategyAddress);
  const controller = await ethers.getContractAt(
    "src/optimism/controller-v7.sol:ControllerV7",
    await oldStrategy.controller()
  );
  const pool = await ethers.getContractAt(poolAbi, await oldStrategy.pool());

  // Calculate oldStrategy tickRangeMultiplier
  const tickSpacing = await pool.tickSpacing();
  const utick = await oldStrategy.tick_upper();
  const ltick = await oldStrategy.tick_lower();
  const tickRangeMultiplier = (utick - ltick) / 2 / tickSpacing;

  // Deploy the new strategy
  const strategyAddr = await deployStrategyV3(
    newStrategyContract,
    tickRangeMultiplier,
    deployer.address,
    deployer.address,
    controller.address,
    deployer.address
  );
  const strategy = await ethers.getContractAt(newStrategyContract, strategyAddr);
  console.log(`✔️ New Strategy deployed at: ${strategy.address}`);

  // Deploy the new jar
  const native = await ethers.getContractAt("src/lib/erc20.sol:ERC20", await strategy.native());
  const token0 = await ethers.getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
  const token1 = await ethers.getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
  const jarContract = "src/optimism/pickle-jar-univ3.sol:PickleJarUniV3";
  const jarName = `pickling ${await token0.symbol()}/${await token1.symbol()} Jar`;
  const jarSymbol = `p${await token0.symbol()}${await token1.symbol()}`;
  const jarAddr = await deployJarV3(
    jarContract,
    jarName,
    jarSymbol,
    pool.address,
    native.address,
    deployer.address,
    deployer.address,
    controller.address
  );
  const jar = await ethers.getContractAt(jarContract, jarAddr);
  console.log(`✔️ New PickleJarV3 deployed at: ${jar.address}`);

  // Deploy migration proxy if not deployed before
  const proxyContract = "src/tmp/univ3-migration-proxy.sol:Proxy";
  let proxyAddr = data[chain].migrationProxy;
  if (!data[chain].migrationProxy) {
    proxyAddr = await deployMigrationProxy();
    console.log("Please update proxy address for " + chain + " chain.");
  }
  const migrationProxy = await ethers.getContractAt(proxyContract, proxyAddr);

  // Transfer Liquidity position from oldStrategy to deployer
  const tokenId = await oldStrategy.tokenId();
  const nftManAddr = await oldStrategy.nftManager();
  const nftManAbi = [
    "function transferFrom(address from, address to, uint256 tokenId)",
    "function ownerOf(uint256) view returns(address)",
    "function WETH9() view returns(address)",
    "function decreaseLiquidity(tuple(uint256 tokenId, uint128 liquidity, uint256 amount0Min, uint256 amount1Min, uint256 deadline)) payable returns(uint256 amount0, uint256 amount1)",
    "function collect(tuple(uint256 tokenId, address recipient, uint128 amount0Max, uint128 amount1Max)) payable returns(uint256 amount0, uint256 amount1)",
    "function positions(uint256) view returns(uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1)",
  ];
  const nftManContract = await ethers.getContractAt(nftManAbi, nftManAddr);

  await callExecuteToProxy(oldStrategy, migrationProxy, "transferFrom", [
    nftManAddr,
    oldStrategy.address,
    deployer.address,
    tokenId,
  ]);

  // Transfer oldStrategy dust to deployer
  const badStratBal0: BigNumber = await token0.balanceOf(oldStrategy.address);
  const badStratBal1: BigNumber = await token1.balanceOf(oldStrategy.address);
  if (!badStratBal0.isZero()) {
    await callExecuteToProxy(oldStrategy, migrationProxy, "transfer", [token0.address, deployer.address, badStratBal0]);
  }
  if (!badStratBal1.isZero()) {
    await callExecuteToProxy(oldStrategy, migrationProxy, "transfer", [token1.address, deployer.address, badStratBal1]);
  }

  // Remove all liquidity from the NFT, then send NFT back to oldStrategy
  const {liquidity} = await nftManContract.positions(tokenId);
  const deadline = Math.floor(Date.now() / 1000) + 300;
  const [amount0, amount1] = await nftManContract.callStatic.decreaseLiquidity([tokenId, liquidity, 0, 0, deadline]);
  await nftManContract.decreaseLiquidity([tokenId, liquidity, 0, 0, deadline]);
  await nftManContract.collect([tokenId, deployer.address, amount0.mul(2), amount1.mul(2)]);
  await nftManContract.transferFrom(deployer.address, oldStrategy.address, tokenId);

  // Remove old strategy from the keeper watch-list
  const keeperAbi = ["function removeStrategy(address)", "function addStrategies(address[])"];
  const keeper = await ethers.getContractAt(keeperAbi, data[chain].keeper);
  await keeper.removeStrategy(oldStrategy.address);

  console.log(
    "First part of the migration is successful. Please call setJar, approveStrategy and setStrategy on the controller before proceeding with the next part."
  );
};

const migrateV3StratAndJar2 = async (
  newJarAddress: string,
  newStrategyAddress: string,
  newStrategyContract: string,
  chain: string
) => {
  const deployer = await ethers.getSigners().then((x) => x[0]);
  console.log(`Deployer: ${deployer.address}`);

  const strategy = await ethers.getContractAt(newStrategyAddress, newStrategyContract);
  const jarContract = "src/optimism/pickle-jar-univ3.sol:PickleJarUniV3";
  const jar = await ethers.getContractAt(newJarAddress, jarContract);
  const controller = await ethers.getContractAt(
    "src/optimism/controller-v7.sol:ControllerV7",
    await strategy.controller()
  );
  const token0 = await ethers.getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
  const token1 = await ethers.getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
  const poolAddr = await strategy.pool();

  // Ensure the new strategy is set on the controller
  const isStrategySet = (await controller.strategies(poolAddr)) === strategy.address;
  const isJarSet = (await controller.jars(poolAddr)) === jar.address;
  if (!isStrategySet || !isJarSet) {
    console.log("Strategy or jar is not set on the controller. Approve and set the new strategy and jar first!");
    return;
  }

  // Mint initial position on the new strategy
  let deployerBalance0 = await token0.balanceOf(deployer.address);
  let deployerBalance1 = await token1.balanceOf(deployer.address);
  await token0.transfer(strategy.address, deployerBalance0.div(10));
  await token1.transfer(strategy.address, deployerBalance1.div(10));
  await strategy.rebalance();

  // Deposit all tokens in the jar
  deployerBalance0 = await token0.balanceOf(deployer.address);
  deployerBalance1 = await token1.balanceOf(deployer.address);
  await token0.approve(jar.address, ethers.constants.MaxUint256);
  await token1.approve(jar.address, ethers.constants.MaxUint256);
  await jar.deposit(deployerBalance0, deployerBalance1);

  // Transfer refunded tokens to the strategy and call rebalance
  deployerBalance0 = await token0.balanceOf(deployer.address);
  deployerBalance1 = await token1.balanceOf(deployer.address);
  await token0.transfer(strategy.address, deployerBalance0);
  await token1.transfer(strategy.address, deployerBalance1);
  await strategy.rebalance();

  // Whitelist harvesters
  await strategy.whitelistHarvesters([tsukeAddr, data[chain].keeper]);

  // Add new strategy to keeper. Remove old one
  const keeperAbi = ["function removeStrategy(address)", "function addStrategies(address[])"];
  const keeper = await ethers.getContractAt(keeperAbi, data[chain].keeper);
  await keeper.addStrategies([strategy.address]);
};

const distributeJarTokensToUsers = async (oldJarAddr: string, newJarAddr: string, chain: string) => {
  const deployer = await ethers.getSigners().then((x) => x[0]);
  console.log(`Deployer: ${deployer.address}`);

  const jarContract = "src/optimism/pickle-jar-univ3.sol:PickleJarUniV3";
  const jar = await ethers.getContractAt(newJarAddr, jarContract);

  const deployerPTokenBalance: BigNumber = await jar.balanceOf(deployer.address);
  const usersOldBalances = await jarSnapshot(oldJarAddr, chain);
  const totalOldBalances = Object.keys(usersOldBalances).reduce(
    (acc, cur) => acc.add(usersOldBalances[cur]),
    BigNumber.from(0)
  );

  const usersNewBalances = {};
  Object.keys(usersOldBalances).forEach((userAddr) => {
    const oldBalance = usersOldBalances[userAddr];
    const newBalance = oldBalance.mul(deployerPTokenBalance).div(totalOldBalances);
    usersNewBalances[userAddr] = newBalance;
  });

  const totalNewBalances = Object.keys(usersNewBalances).reduce(
    (acc, cur) => acc.add(usersNewBalances[cur]),
    BigNumber.from(0)
  );
  console.log("Deployer pToken Balance: " + deployerPTokenBalance.toString());
  console.log("pTokens to be dispersed: " + totalNewBalances.toString());
  if (totalNewBalances.gt(deployerPTokenBalance)) {
    console.log("Users' total new balances is more than what the deployer have!");
    return;
  }

  const usersAddresses = [];
  const usersShares = [];
  Object.keys(usersNewBalances).forEach((userAddr) => {
    usersAddresses.push(userAddr);
    usersShares.push(usersNewBalances[userAddr]);
  });

  const proxyContract = "src/tmp/univ3-migration-proxy.sol:Proxy";
  let proxyAddr = data[chain].migrationProxy;
  if (!data[chain].migrationProxy) {
    console.log("Please update migration proxy address for " + chain + " chain.");
    return;
  }
  const migrationProxy = await ethers.getContractAt(proxyContract, proxyAddr);

  await jar.approve(migrationProxy.address, deployerPTokenBalance);
  await migrationProxy.multisend(jar.address, usersAddresses, usersShares);
};

// Functions
const main = async () => {
  // Notes:
  // 1) Pause the old jar.
  // 2) Transfer governance & timelock of the oldStrategy to deployer.
  // 3) Run migrateV3StratAndJar1().
  // 4) Set the new jar on the controller.
  // 5) Approve & set the new strategy on controller.
  // 6) Run migrateV3StratAndJar2().
  // 7) Run distributeJarTokensToUsers().

  const chain = "ARB";
  const strategyData = data[chain].strats[0];
  const newJarAddr = "";
  const newStrategyAddr = "";
  try {
    await migrateV3StratAndJar1(strategyData.oldStrategyAddr, strategyData.newStrategyContract, chain);
    await migrateV3StratAndJar2(newJarAddr, newStrategyAddr, strategyData.newStrategyContract, chain);
    await distributeJarTokensToUsers("", newJarAddr, chain);
  } catch (error) {
    console.log("Something went wrong!");
    console.log("Error:\n" + error);
  }
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
