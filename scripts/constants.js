const DAPP_OUT = require("../out/dapp.sol.json");
const DAPP_CONTRACTS = DAPP_OUT.contracts;

const ADDRESSES = {
  CurveFi: {
    VotingEscrow: "0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2",
    GaugeController: "0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB",
    SmartContractChecker: "0xca719728Ef172d0961768581fdF35CB116e0B7a4",
    DAO: "0x40907540d8a6c65c637785e8f8b742ae6b0b9968",
    sCRVGauge: "0xA90996896660DEcC6E997655E065b23788857849",
  },
  ERC20: {
    DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    CRV: "0xD533a949740bb3306d119CC777fa900bA034cd52",
    WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    veCRV: "0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2",
  },
  ETH: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
  UniswapV2: {
    Router2: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  },
};

const KEYS = {
  Pickle: {
    PickleJar: "src/pickle-jar.sol:PickleJar",
    ControllerV4: "src/controller-v4.sol:ControllerV4",
    Converters: {
      CurveCurve:
        "src/jar-converters/curve-curve-converter.sol:CurveCurveJarConverter",
      CurveUni:
        "src/jar-converters/curve-uni-converter.sol:CurveUniJarConverter",
      UniCurve:
        "src/jar-converters/uni-curve-converter.sol:UniCurveJarConverter",
      UniUni: "src/jar-converters/uni-uni-converter.sol:UniUniJarConverter",
    },
    Strategies: {
      StrategyCmpdDaiV2:
        "src/strategies/compound/strategy-cmpd-dai-v2.sol:StrategyCmpdDaiV2",
      StrategyCurve3CRVv2:
        "src/strategies/curve/strategy-curve-3crv-v2.sol:StrategyCurve3CRVv2",
      StrategyCurveRenCRVv2:
        "src/strategies/curve/strategy-curve-rencrv-v2.sol:StrategyCurveRenCRVv2",
      StrategyCurveSCRVv3_2:
        "src/strategies/curve/strategy-curve-scrv-v3_2.sol:StrategyCurveSCRVv3_2",
      StrategyUniEthDaiLpV4:
        "src/strategies/uniswapv2/strategy-uni-eth-dai-lp-v4.sol:StrategyUniEthDaiLpV4",
      StrategyUniEthUsdcLpV4:
        "src/strategies/uniswapv2/strategy-uni-eth-usdc-lp-v4.sol:StrategyUniEthUsdcLpV4",
      StrategyUniEthUsdtLpV4:
        "src/strategies/uniswapv2/strategy-uni-eth-usdt-lp-v4.sol:StrategyUniEthUsdtLpV4",
      StrategyUniEthWBtcLpV2:
        "src/strategies/uniswapv2/strategy-uni-eth-wbtc-lp-v2.sol:StrategyUniEthWBtcLpV2",
    },
  },
};

const PickleJar = DAPP_CONTRACTS[KEYS.Pickle.PickleJar];
const ControllerV4 = DAPP_CONTRACTS[KEYS.Pickle.ControllerV4];

const CurveCurve = DAPP_CONTRACTS[KEYS.Pickle.Converters.CurveCurve];
const CurveUni = DAPP_CONTRACTS[KEYS.Pickle.Converters.CurveUni];
const UniCurve = DAPP_CONTRACTS[KEYS.Pickle.Converters.UniCurve];
const UniUni = DAPP_CONTRACTS[KEYS.Pickle.Converters.UniUni];

const StrategyCmpdDaiV2 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyCmpdDaiV2];
const StrategyCurve3CRVv2 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyCurve3CRVv2];
const StrategyCurveRenCRVv2 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyCurveRenCRVv2];
const StrategyCurveSCRVv3_2 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyCurveSCRVv3_2];
const StrategyUniEthDaiLpV4 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyUniEthDaiLpV4];
const StrategyUniEthUsdcLpV4 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyUniEthUsdcLpV4];
const StrategyUniEthUsdtLpV4 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyUniEthUsdtLpV4];
const StrategyUniEthWBtcLpV2 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyUniEthWBtcLpV2];

const ABIS = {
  Pickle: {
    PickleJar: PickleJar.abi,
    ControllerV4: ControllerV4.abi,
    Converters: {
      CurveCurve: CurveCurve.abi,
      CurveUni: CurveUni.abi,
      UniCurve: UniCurve.abi,
      UniUni: UniUni.abi,
    },
    Strategies: {
      StrategyCmpdDaiV2: StrategyCmpdDaiV2.abi,
      StrategyCurve3CRVv2: StrategyCurve3CRVv2.abi,
      StrategyCurveRenCRVv2: StrategyCurveRenCRVv2.abi,
      StrategyCurveSCRVv3_2: StrategyCurveSCRVv3_2.abi,
      StrategyUniEthDaiLpV4: StrategyUniEthDaiLpV4.abi,
      StrategyUniEthUsdcLpV4: StrategyUniEthUsdcLpV4.abi,
      StrategyUniEthUsdtLpV4: StrategyUniEthUsdtLpV4.abi,
      StrategyUniEthWBtcLpV2: StrategyUniEthWBtcLpV2.abi,
    },
  },
  UniswapV2: {
    Router2: DAPP_CONTRACTS["src/interfaces/uniswapv2.sol:UniswapRouterV2"].abi,
  },
};

const BYTECODE = {
  Pickle: {
    PickleJar: PickleJar.bin,
    ControllerV4: ControllerV4.bin,
    Converters: {
      CurveCurve: CurveCurve.bin,
      CurveUni: CurveUni.bin,
      UniCurve: UniCurve.bin,
      UniUni: UniUni.bin,
    },
    Strategies: {
      StrategyCmpdDaiV2: StrategyCmpdDaiV2.bin,
      StrategyCurve3CRVv2: StrategyCurve3CRVv2.bin,
      StrategyCurveRenCRVv2: StrategyCurveRenCRVv2.bin,
      StrategyCurveSCRVv3_2: StrategyCurveSCRVv3_2.bin,
      StrategyUniEthDaiLpV4: StrategyUniEthDaiLpV4.bin,
      StrategyUniEthUsdcLpV4: StrategyUniEthUsdcLpV4.bin,
      StrategyUniEthUsdtLpV4: StrategyUniEthUsdtLpV4.bin,
      StrategyUniEthWBtcLpV2: StrategyUniEthWBtcLpV2.bin,
    },
  },
};

module.exports = {
  KEYS,
  ADDRESSES,
  ABIS,
  BYTECODE,
};
