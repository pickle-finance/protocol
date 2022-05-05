const {
  toWei,
  deployContract,
  getContractAt,
  increaseTime,
  increaseBlock,
  unlockAccount,
} = require("../../utils/testHelper");
const {getWantFromWhale} = require("../../utils/setupHelper");
const {BigNumber: BN} = require("ethers");
/*
StrategyProxy: 0x552D92Ad2bb3Aba00872491ea2DC5d6EC3B8A31D
veFXSVault: 0x62826760CC53AE076a7523Fd9dCF4f8Dbb1dA140
locker: 0xd639C2eA4eEFfAD39b599410d00252E6c80008DF

Frax/Dai Strategy: 0x219747CA16907330FAe76673facB6e67860ED4C9
Frax/Dai Jar: 0xe7b69a17B3531d01FCEAd66FaF7d9f7655469267

Frax/USDC Strategy: 0x68d467443529f4cC24055ff244826F624dbEff19
Frax/USDC Jar: 0x7f3514CBC6825410Ca3fA4deA41d46964a953Afb

ProxyAdmin: 0xEB6044CF48b07ba87D7922362f1aFf5C52FD7Ed3
AdminUpgradableProxy: 0x7B5916C61bCEeaa2646cf49D9541ac6F5DCe3637
implController: 0xfa601B32b0B731981845c86557B54e66D2eb23fA
*/

describe("StrategyFraxTemple", () => {
  const FRAX_TEMPLE_POOL = "0x6021444f1706f15465bEe85463BCc7d7cC17Fc03";
  const FRAX_TEMPLE_SWAP = "0x8A5058100E60e8F7C42305eb505B12785bbA3BcA";
  const FRAX_TEMPLE_GAUGE = "0x10460d02226d6ef7B2419aE150E6377BdbB7Ef16";
  const FRAX_DAI_POOL = "0x97e7d56A0408570bA1a7852De36350f7713906ec";
  const FRAX_DAI_GAUGE = "0xF22471AC2156B489CC4a59092c56713F813ff53e";
  const FRAX_USDC_POOL = "0xc63B0708E2F7e69CB8A1df0e1389A98C35A76D52";
  const FRAX_USDC_GAUGE = "0x3EF26504dbc8Dd7B7aa3E97Bc9f3813a9FC0B4B0";
  const FraxToken = "0x853d955acef822db058eb8505911ed77f175b99e";
  const TEMPLEToken = "0x470EBf5f030Ed85Fc1ed4C2d36B9DD02e77CF1b7";
  const FXSToken = "0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0";
  const SMARTCHECKER = "0x53c13BA8834a1567474b19822aAD85c6F90D9f9F";
  const GOVADDR = "0x000000000088E0120F9E6652CC058AeC07564F69";
  const TIMELOCK = "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3";
  const DAIToken = "0x6b175474e89094c44da98b954eedeac495271d0f";
  const USDCToken = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

  let alice;
  let frax, temple, fxs, fraxDeployer, escrow;
  let strategy, pickleJar, controller, proxyAdmin, multisig, strategyProxy, oldStrategyProxy, locker, veFxsVault;
  let smartChecker;
  let governance, strategist, devfund, treasury, timelock;
  let preTestSnapshotID;
  let usdcStrategy, daiStrategy, usdcJar, daiJar, dai, usdc;
  let lockerGovernance;

  before("Setup Contracts", async () => {
    [alice, bob, charles, devfund, treasury] = await hre.ethers.getSigners();

    lockerGovernance = await unlockAccount("0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C");
    governance = await unlockAccount(GOVADDR);
    multisig = await unlockAccount("0x9d074E37d408542FD38be78848e8814AFB38db17");
    timelock = await unlockAccount(TIMELOCK);
    strategist = governance;
    proxyAdmin = await getContractAt("ProxyAdmin", "0x7B5916C61bCEeaa2646cf49D9541ac6F5DCe3637");
    console.log("✅ ProxyAdmin is deployed at ", proxyAdmin.address);


    controllerv7 = await getContractAt("src/controller-v7.sol:ControllerV7", "0x7B5916C61bCEeaa2646cf49D9541ac6F5DCe3637");
    //TODO get controllerv4
    controller = await getContractAt("src/controller-v4.sol:ControllerV4", "0x6847259b2B3A4c17e7c43C54409810aF48bA5210");

    console.log("✅ Controller is deployed at ", controller.address);

    locker = await getContractAt("FXSLocker", "0xd639C2eA4eEFfAD39b599410d00252E6c80008DF");
    console.log("✅ Locker is deployed at ", locker.address);

    escrow = await getContractAt("VoteEscrow", "0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0");

    oldStrategyProxy = await getContractAt("StrategyProxy", "0x552D92Ad2bb3Aba00872491ea2DC5d6EC3B8A31D");

    strategyProxy = await deployContract("StrategyProxyV2");
    await strategyProxy.setGovernance(GOVADDR);
    console.log("✅ StrategyProxy is deployed at ", strategyProxy.address);

    await locker.connect(lockerGovernance).setStrategy(strategyProxy.address);
    await strategyProxy.connect(governance).setLocker(locker.address);

    strategy = await deployContract(
      "StrategyFraxTempleUniV2",
      GOVADDR,
      GOVADDR,
      controller.address,
      GOVADDR
    );

    await strategy.connect(governance).setStrategyProxy(strategyProxy.address);

    await strategyProxy.connect(governance).approveStrategy(
      FRAX_TEMPLE_GAUGE,
      strategy.address,
      "0xc00007b0000000000000000000000000d639c2ea4eeffad39b599410d00252e6c80008df"
    );


    pickleJar = await deployContract(
      "PickleJar",
      FRAX_TEMPLE_POOL,
      GOVADDR,
      GOVADDR,
      controller.address
    );
    console.log("✅ PickleJar is deployed at ", pickleJar.address);

    usdcStrategy = await getContractAt("StrategyFraxUsdcUniV3", "0x68d467443529f4cC24055ff244826F624dbEff19");
    daiStrategy = await getContractAt("StrategyFraxDaiUniV3","0x219747CA16907330FAe76673facB6e67860ED4C9");
    usdcJar = await getContractAt("PickleJarStablesUniV3","0x7f3514CBC6825410Ca3fA4deA41d46964a953Afb");
    daiJar = await getContractAt("PickleJarStablesUniV3","0xe7b69a17B3531d01FCEAd66FaF7d9f7655469267");

    await strategyProxy.connect(governance).approveStrategy(
      FRAX_USDC_GAUGE,
      "0x68d467443529f4cC24055ff244826F624dbEff19",
      "0x3d18b912"
    );

    await strategyProxy.connect(governance).approveStrategy(
      FRAX_DAI_GAUGE,
      "0x219747CA16907330FAe76673facB6e67860ED4C9",
      "0x3d18b912"
    );
    await alice.sendTransaction({
      to: "0x9d074E37d408542FD38be78848e8814AFB38db17",
      value: toWei(5),
    });

    await alice.sendTransaction({
      to: TIMELOCK,
      value: toWei(5),
    });

    await controller.connect(multisig).setJar(FRAX_TEMPLE_POOL, pickleJar.address);
    await controller.connect(timelock).approveStrategy(FRAX_TEMPLE_POOL, strategy.address);
    await controller.connect(multisig).setStrategy(FRAX_TEMPLE_POOL, strategy.address);

    veFxsVault = await getContractAt("veFXSVault", "0x62826760CC53AE076a7523Fd9dCF4f8Dbb1dA140");
    console.log("✅ veFxsVault is deployed at ", veFxsVault.address);

    await veFxsVault.connect(governance).setProxy(strategyProxy.address);
    await veFxsVault.connect(governance).setFeeDistribution(strategyProxy.address);
    await veFxsVault.connect(governance).setLocker(locker.address);

    await strategyProxy.connect(governance).setFXSVault(veFxsVault.address);

    frax = await getContractAt("ERC20", FraxToken);
    temple = await getContractAt("ERC20", TEMPLEToken);
    fxs = await getContractAt("ERC20", FXSToken);
    dai = await getContractAt("ERC20", DAIToken);
    usdc = await getContractAt("ERC20", USDCToken);
    pool = await getContractAt("ERC20", FRAX_TEMPLE_POOL);
    templeRouter = await getContractAt(poolABI, FRAX_TEMPLE_SWAP);

    await getWantFromWhale(FraxToken, toWei(10000), alice, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");

    await getWantFromWhale(TEMPLEToken, toWei(10000), alice, "0xbfc2790ca5f7f1649ffc98d0ffd2573b716cbd0d");

    await getWantFromWhale(FraxToken, toWei(10000), bob, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");

    await getWantFromWhale(TEMPLEToken, toWei(10000), bob, "0xbfc2790ca5f7f1649ffc98d0ffd2573b716cbd0d");

    await getWantFromWhale(FraxToken, toWei(10000), charles, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");

    await getWantFromWhale(TEMPLEToken, toWei(10000), charles, "0xbfc2790ca5f7f1649ffc98d0ffd2573b716cbd0d");

    await getWantFromWhale(FXSToken, toWei(1000000), alice, "0xF977814e90dA44bFA03b6295A0616a897441aceC");

    // transfer FXS to distributor
    await fxs.connect(alice).transfer("0x278dc748eda1d8efef1adfb518542612b49fcd34", toWei(5000));
    // transfer FXS to gauge
    await fxs.connect(alice).transfer(FRAX_TEMPLE_GAUGE, toWei(700000));
  });

  it("should harvest correctly", async () => {
    let depositAmount = toWei(200);

    let aliceShare, bobShare, charlesShare;

    console.log("=============== Alice deposit ==============");
    await deposit(alice, depositAmount);
    const _amt = await pool.balanceOf(pickleJar.address);
    console.log("Calling Earn:", _amt.toString());
    await pickleJar.earn();
    console.log("Calling Harvest:");
    await harvest(pickleJar, strategy);

    console.log("=============== Bob deposit ==============");
    depositAmount = toWei(400);

    await deposit(bob, depositAmount);
    await pickleJar.earn();
    await harvest(pickleJar, strategy);

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    aliceShare = await pickleJar.balanceOf(alice.address);
    console.log("Alice share amount => ", aliceShare.toString());

    console.log("===============Alice partial withdraw==============");
    console.log("Alice temple balance before withdrawal => ", (await temple.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    await pickleJar.connect(alice).withdraw(aliceShare.div(BN.from(2)));

    console.log("Alice temple balance after withdrawal => ", (await temple.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== Charles deposit ==============");

    depositAmount = toWei(700);

    await deposit(charles, depositAmount);

    console.log("===============Bob withdraw==============");
    console.log("Bob temple balance before withdrawal => ", (await temple.balanceOf(bob.address)).toString());
    console.log("Bob frax balance before withdrawal => ", (await frax.balanceOf(bob.address)).toString());
    await pickleJar.connect(bob).withdrawAll();

    console.log("Bob temple balance after withdrawal => ", (await temple.balanceOf(bob.address)).toString());
    console.log("Bob frax balance after withdrawal => ", (await frax.balanceOf(bob.address)).toString());

    await harvest(pickleJar, strategy);
    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    await pickleJar.earn();

    await increaseTime(60 * 60 * 24 * 1); //travel 14 days

    console.log("=============== Controller withdraw ===============");
    console.log(
      "PickleJar temple balance before withdrawal => ",
      (await temple.balanceOf(pickleJar.address)).toString()
    );
    console.log("PickleJar frax balance before withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    await controller.connect(lockerGovernance).withdrawAll(FRAX_TEMPLE_POOL,{gasLimit:2000000});

    console.log(
      "PickleJar temple balance after withdrawal => ",
      (await temple.balanceOf(pickleJar.address)).toString()
    );
    console.log("PickleJar frax balance after withdrawal => ", (await frax.balanceOf(pickleJar.address)).toString());

    console.log("===============Alice Full withdraw==============");

    console.log("Alice temple balance before withdrawal => ", (await temple.balanceOf(alice.address)).toString());
    console.log("Alice frax balance before withdrawal => ", (await frax.balanceOf(alice.address)).toString());
    await pickleJar.connect(alice).withdrawAll();

    console.log("Alice temple balance after withdrawal => ", (await temple.balanceOf(alice.address)).toString());
    console.log("Alice frax balance after withdrawal => ", (await frax.balanceOf(alice.address)).toString());

    console.log("=============== charles withdraw ==============");
    console.log("Charles temple balance before withdrawal => ", (await temple.balanceOf(charles.address)).toString());
    console.log("Charles frax balance before withdrawal => ", (await frax.balanceOf(charles.address)).toString());
    await pickleJar.connect(charles).withdrawAll();

    console.log("Charles temple balance after withdrawal => ", (await temple.balanceOf(charles.address)).toString());
    console.log("Charles frax balance after withdrawal => ", (await frax.balanceOf(charles.address)).toString());

    console.log("------------------ Finished -----------------------");

    console.log("Treasury temple balance => ", (await temple.balanceOf(treasury.address)).toString());
    console.log("Treasury frax balance => ", (await frax.balanceOf(treasury.address)).toString());
    console.log("Treasury Frax/Temple LP balance => ", (await pool.balanceOf(treasury.address)).toString());

    console.log("Strategy temple balance => ", (await temple.balanceOf(strategy.address)).toString());
    console.log("Strategy frax balance => ", (await frax.balanceOf(strategy.address)).toString());
    console.log("Strategy fxs balance => ", (await fxs.balanceOf(strategy.address)).toString());

    console.log("PickleJar temple balance => ", (await temple.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar frax balance => ", (await frax.balanceOf(pickleJar.address)).toString());
    console.log("PickleJar fxs balance => ", (await fxs.balanceOf(pickleJar.address)).toString());

    console.log("Locker temple balance => ", (await temple.balanceOf(locker.address)).toString());
    console.log("Locker frax balance => ", (await frax.balanceOf(locker.address)).toString());
    console.log("Locker fxs balance => ", (await fxs.balanceOf(locker.address)).toString());

    console.log("StrategyProxy temple balance => ", (await temple.balanceOf(strategyProxy.address)).toString());
    console.log("StrategyProxy frax balance => ", (await frax.balanceOf(strategyProxy.address)).toString());
    console.log("StrategyProxy fxs balance => ", (await fxs.balanceOf(strategyProxy.address)).toString());
  });
  it("Migrate UniV3 Strategies", async () => {
    /*
    usdcStrategy = await getContractAt("StrategyFraxUsdcUniV3", "0x68d467443529f4cC24055ff244826F624dbEff19");
    daiStrategy = await getContractAt("StrategyFraxDaiUniV3","0x219747CA16907330FAe76673facB6e67860ED4C9");
    usdcJar = await getContractAt("PickleJarStablesUniV3","0x7f3514CBC6825410Ca3fA4deA41d46964a953Afb");
    daiJar
    */

    await usdcStrategy.connect(governance).setStrategyProxy(strategyProxy.address);
    await daiStrategy.connect(governance).setStrategyProxy(strategyProxy.address);

    await getWantFromWhale(FraxToken, toWei(100000), alice, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");
    await getWantFromWhale(DAIToken, toWei(100000), alice, "0x921760e71fb58dcc8de902ce81453e9e3d7fe253");

    await getWantFromWhale(FraxToken, toWei(100000), alice, "0x820A9eb227BF770A9dd28829380d53B76eAf1209");
    await getWantFromWhale(USDCToken, "100000000000000", alice, "0xE78388b4CE79068e89Bf8aA7f218eF6b9AB0e9d0");

    console.log("=============== Alice deposit Frax/USDC ==============");

    let depositA = toWei(20000);
    let depositB = await getAmountB(daiJar, depositA);

    await depositV3(daiJar, alice, depositA, depositB);
    console.log("Deposit V3 Done");
    await daiJar.earn();
    console.log("Earn Complete");
    await harvest(daiJar, daiStrategy);
    console.log("Harvest complete");
  });

const getAmountB = async (jar, amountA) => {
  const proportion = await jar.getProportion();
  const amountB = amountA.mul(proportion).div(hre.ethers.BigNumber.from("1000000000000000000"));
  return amountB;
};

  const deposit = async (user, depositAmount) => {
    await depositing(user, depositAmount);
    const _amt = await pool.balanceOf(user.address);
    await pool.connect(user).approve(pickleJar.address, _amt);

    await pickleJar.connect(user).deposit(_amt);
  };
  const depositV3 = async (jar, user, depositA, depositB) => {
    await frax.connect(user).approve(jar.address, depositA);
    await usdc.connect(user).approve(jar.address, depositB);
    console.log("depositA => ", depositA.toString());
    console.log("depositB => ", depositB.toString());

    await jar.connect(user).deposit(depositA, depositB);
  };

  const harvest = async (jar, strat) => {
    console.log("============ Harvest Started ==============");
    console.log("Ratio before harvest => ", (await jar.getRatio()).toString());
    await increaseTime(60 * 60 * 24 * 14); //travel 30 days
    await increaseBlock(1000);
    console.log("Amount Harvestable => ", (await strat.getHarvestable()).toString());
    await strat.connect(governance).harvest({gasLimit: 10000000});
    console.log("Amount Harvestable after => ", (await strat.getHarvestable()).toString());
    console.log("Ratio after harvest => ", (await jar.getRatio()).toString());
    console.log("============ Harvest Ended ==============");
  };

  const depositing = async (user, amount) => {
    // getting timestamp
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    await temple.connect(user).approve(FRAX_TEMPLE_SWAP, amount);
    await frax.connect(user).approve(FRAX_TEMPLE_SWAP, amount);
    await templeRouter.connect(user).addLiquidity(amount, amount, 0, 0, user.address, timestampBefore + 60);
  };

  const poolABI = [
    {
      inputs: [
        {internalType: "contract IUniswapV2Pair", name: "_pair", type: "address"},
        {internalType: "contract TempleERC20Token", name: "_templeToken", type: "address"},
        {internalType: "contract IERC20", name: "_fraxToken", type: "address"},
        {internalType: "contract ITempleTreasury", name: "_templeTreasury", type: "address"},
        {internalType: "address", name: "_protocolMintEarningsAccount", type: "address"},
        {
          components: [
            {internalType: "uint256", name: "frax", type: "uint256"},
            {internalType: "uint256", name: "temple", type: "uint256"},
          ],
          internalType: "struct TempleFraxAMMRouter.Price",
          name: "_dynamicThresholdPrice",
          type: "tuple",
        },
        {internalType: "uint256", name: "_dynamicThresholdDecayPerBlock", type: "uint256"},
        {
          components: [
            {internalType: "uint256", name: "frax", type: "uint256"},
            {internalType: "uint256", name: "temple", type: "uint256"},
          ],
          internalType: "struct TempleFraxAMMRouter.Price",
          name: "_interpolateFromPrice",
          type: "tuple",
        },
        {
          components: [
            {internalType: "uint256", name: "frax", type: "uint256"},
            {internalType: "uint256", name: "temple", type: "uint256"},
          ],
          internalType: "struct TempleFraxAMMRouter.Price",
          name: "_interpolateToPrice",
          type: "tuple",
        },
      ],
      stateMutability: "nonpayable",
      type: "constructor",
    },
    {
      anonymous: false,
      inputs: [{indexed: false, internalType: "uint256", name: "currDynamicThresholdTemple", type: "uint256"}],
      name: "DynamicThresholdChange",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {indexed: true, internalType: "address", name: "previousOwner", type: "address"},
        {indexed: true, internalType: "address", name: "newOwner", type: "address"},
      ],
      name: "OwnershipTransferred",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [{indexed: false, internalType: "uint256", name: "blockNumber", type: "uint256"}],
      name: "PriceCrossedBelowDynamicThreshold",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {indexed: true, internalType: "bytes32", name: "role", type: "bytes32"},
        {indexed: true, internalType: "bytes32", name: "previousAdminRole", type: "bytes32"},
        {indexed: true, internalType: "bytes32", name: "newAdminRole", type: "bytes32"},
      ],
      name: "RoleAdminChanged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {indexed: true, internalType: "bytes32", name: "role", type: "bytes32"},
        {indexed: true, internalType: "address", name: "account", type: "address"},
        {indexed: true, internalType: "address", name: "sender", type: "address"},
      ],
      name: "RoleGranted",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {indexed: true, internalType: "bytes32", name: "role", type: "bytes32"},
        {indexed: true, internalType: "address", name: "account", type: "address"},
        {indexed: true, internalType: "address", name: "sender", type: "address"},
      ],
      name: "RoleRevoked",
      type: "event",
    },
    {
      inputs: [],
      name: "CAN_ADD_ALLOWED_USER",
      outputs: [{internalType: "bytes32", name: "", type: "bytes32"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "DEFAULT_ADMIN_ROLE",
      outputs: [{internalType: "bytes32", name: "", type: "bytes32"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "DYNAMIC_THRESHOLD_INCREASE_DENOMINATOR",
      outputs: [{internalType: "uint256", name: "", type: "uint256"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [{internalType: "address", name: "userAddress", type: "address"}],
      name: "addAllowedUser",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "amountADesired", type: "uint256"},
        {internalType: "uint256", name: "amountBDesired", type: "uint256"},
        {internalType: "uint256", name: "amountAMin", type: "uint256"},
        {internalType: "uint256", name: "amountBMin", type: "uint256"},
        {internalType: "address", name: "to", type: "address"},
        {internalType: "uint256", name: "deadline", type: "uint256"},
      ],
      name: "addLiquidity",
      outputs: [
        {internalType: "uint256", name: "amountA", type: "uint256"},
        {internalType: "uint256", name: "amountB", type: "uint256"},
        {internalType: "uint256", name: "liquidity", type: "uint256"},
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{internalType: "address", name: "", type: "address"}],
      name: "allowed",
      outputs: [{internalType: "bool", name: "", type: "bool"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "dynamicThresholdDecayPerBlock",
      outputs: [{internalType: "uint256", name: "", type: "uint256"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "dynamicThresholdIncreasePct",
      outputs: [{internalType: "uint256", name: "", type: "uint256"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "dynamicThresholdPrice",
      outputs: [
        {internalType: "uint256", name: "frax", type: "uint256"},
        {internalType: "uint256", name: "temple", type: "uint256"},
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "dynamicThresholdPriceWithDecay",
      outputs: [
        {internalType: "uint256", name: "frax", type: "uint256"},
        {internalType: "uint256", name: "temple", type: "uint256"},
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "fraxToken",
      outputs: [{internalType: "contract IERC20", name: "", type: "address"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "amountIn", type: "uint256"},
        {internalType: "uint256", name: "reserveIn", type: "uint256"},
        {internalType: "uint256", name: "reserveOut", type: "uint256"},
      ],
      name: "getAmountOut",
      outputs: [{internalType: "uint256", name: "amountOut", type: "uint256"}],
      stateMutability: "pure",
      type: "function",
    },
    {
      inputs: [{internalType: "bytes32", name: "role", type: "bytes32"}],
      name: "getRoleAdmin",
      outputs: [{internalType: "bytes32", name: "", type: "bytes32"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {internalType: "bytes32", name: "role", type: "bytes32"},
        {internalType: "address", name: "account", type: "address"},
      ],
      name: "grantRole",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {internalType: "bytes32", name: "role", type: "bytes32"},
        {internalType: "address", name: "account", type: "address"},
      ],
      name: "hasRole",
      outputs: [{internalType: "bool", name: "", type: "bool"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "interpolateFromPrice",
      outputs: [
        {internalType: "uint256", name: "frax", type: "uint256"},
        {internalType: "uint256", name: "temple", type: "uint256"},
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "interpolateToPrice",
      outputs: [
        {internalType: "uint256", name: "frax", type: "uint256"},
        {internalType: "uint256", name: "temple", type: "uint256"},
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "temple", type: "uint256"},
        {internalType: "uint256", name: "frax", type: "uint256"},
      ],
      name: "mintRatioAt",
      outputs: [
        {internalType: "uint256", name: "numerator", type: "uint256"},
        {internalType: "uint256", name: "denominator", type: "uint256"},
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "openAccessEnabled",
      outputs: [{internalType: "bool", name: "", type: "bool"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "owner",
      outputs: [{internalType: "address", name: "", type: "address"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "pair",
      outputs: [{internalType: "contract IUniswapV2Pair", name: "", type: "address"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "priceCrossedBelowDynamicThresholdBlock",
      outputs: [{internalType: "uint256", name: "", type: "uint256"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "amountA", type: "uint256"},
        {internalType: "uint256", name: "reserveA", type: "uint256"},
        {internalType: "uint256", name: "reserveB", type: "uint256"},
      ],
      name: "quote",
      outputs: [{internalType: "uint256", name: "amountB", type: "uint256"}],
      stateMutability: "pure",
      type: "function",
    },
    {
      inputs: [{internalType: "address", name: "userAddress", type: "address"}],
      name: "removeAllowedUser",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "liquidity", type: "uint256"},
        {internalType: "uint256", name: "amountAMin", type: "uint256"},
        {internalType: "uint256", name: "amountBMin", type: "uint256"},
        {internalType: "address", name: "to", type: "address"},
        {internalType: "uint256", name: "deadline", type: "uint256"},
      ],
      name: "removeLiquidity",
      outputs: [
        {internalType: "uint256", name: "amountA", type: "uint256"},
        {internalType: "uint256", name: "amountB", type: "uint256"},
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {inputs: [], name: "renounceOwnership", outputs: [], stateMutability: "nonpayable", type: "function"},
    {
      inputs: [
        {internalType: "bytes32", name: "role", type: "bytes32"},
        {internalType: "address", name: "account", type: "address"},
      ],
      name: "renounceRole",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {internalType: "bytes32", name: "role", type: "bytes32"},
        {internalType: "address", name: "account", type: "address"},
      ],
      name: "revokeRole",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{internalType: "uint256", name: "_dynamicThresholdDecayPerBlock", type: "uint256"}],
      name: "setDynamicThresholdDecayPerBlock",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{internalType: "uint256", name: "_dynamicThresholdIncreasePct", type: "uint256"}],
      name: "setDynamicThresholdIncreasePct",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "frax", type: "uint256"},
        {internalType: "uint256", name: "temple", type: "uint256"},
      ],
      name: "setInterpolateFromPrice",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "frax", type: "uint256"},
        {internalType: "uint256", name: "temple", type: "uint256"},
      ],
      name: "setInterpolateToPrice",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{internalType: "address", name: "_protocolMintEarningsAccount", type: "address"}],
      name: "setProtocolMintEarningsAccount",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{internalType: "bytes4", name: "interfaceId", type: "bytes4"}],
      name: "supportsInterface",
      outputs: [{internalType: "bool", name: "", type: "bool"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "amountIn", type: "uint256"},
        {internalType: "uint256", name: "amountOutMin", type: "uint256"},
        {internalType: "address", name: "to", type: "address"},
        {internalType: "uint256", name: "deadline", type: "uint256"},
      ],
      name: "swapExactFraxForTemple",
      outputs: [{internalType: "uint256", name: "amountOut", type: "uint256"}],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{internalType: "uint256", name: "amountIn", type: "uint256"}],
      name: "swapExactFraxForTempleQuote",
      outputs: [
        {internalType: "uint256", name: "amountInAMM", type: "uint256"},
        {internalType: "uint256", name: "amountInProtocol", type: "uint256"},
        {internalType: "uint256", name: "amountOutAMM", type: "uint256"},
        {internalType: "uint256", name: "amountOutProtocol", type: "uint256"},
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {internalType: "uint256", name: "amountIn", type: "uint256"},
        {internalType: "uint256", name: "amountOutMin", type: "uint256"},
        {internalType: "address", name: "to", type: "address"},
        {internalType: "uint256", name: "deadline", type: "uint256"},
      ],
      name: "swapExactTempleForFrax",
      outputs: [{internalType: "uint256", name: "", type: "uint256"}],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{internalType: "uint256", name: "amountIn", type: "uint256"}],
      name: "swapExactTempleForFraxQuote",
      outputs: [
        {internalType: "bool", name: "priceBelowIV", type: "bool"},
        {internalType: "bool", name: "willCrossDynamicThreshold", type: "bool"},
        {internalType: "uint256", name: "amountOut", type: "uint256"},
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "templeToken",
      outputs: [{internalType: "contract TempleERC20Token", name: "", type: "address"}],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "templeTreasury",
      outputs: [{internalType: "contract ITempleTreasury", name: "", type: "address"}],
      stateMutability: "view",
      type: "function",
    },
    {inputs: [], name: "toggleOpenAccess", outputs: [], stateMutability: "nonpayable", type: "function"},
    {
      inputs: [{internalType: "address", name: "newOwner", type: "address"}],
      name: "transferOwnership",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {internalType: "address", name: "token", type: "address"},
        {internalType: "address", name: "to", type: "address"},
        {internalType: "uint256", name: "amount", type: "uint256"},
      ],
      name: "withdraw",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
  ];
});
