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
    CRV: "0xD533a949740bb3306d119CC777fa900bA034cd52",
    WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    veCRV: "0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2",
  },
  ETH: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
  UniswapV2: {
    Router2: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  },
};

const PickleJar = DAPP_CONTRACTS["src/pickle-jar.sol:PickleJar"];
const ControllerV3 = DAPP_CONTRACTS["src/controller-v3.sol:ControllerV3"];
const StrategyCurve3CRVv1 =
  DAPP_CONTRACTS[
    "src/strategies/curve/strategy-curve-3crv-v1.sol:StrategyCurve3CRVv1"
  ];
const StrategyCurveRenCRVv1 =
  DAPP_CONTRACTS[
    "src/strategies/curve/strategy-curve-rencrv-v1.sol:StrategyCurveRenCRVv1"
  ];
const StrategyUniEthWBtcLpV1 =
  DAPP_CONTRACTS[
    "src/strategies/uniswapv2/strategy-uni-eth-wbtc-lp-v1.sol:StrategyUniEthWBtcLpV1"
  ];

const ABIS = {
  Pickle: {
    PickleJar: PickleJar.abi,
    ControllerV3: ControllerV3.abi,
    Strategies: {
      StrategyCurve3CRVv1: StrategyCurve3CRVv1.abi,
      StrategyCurveRenCRVv1: StrategyCurveRenCRVv1.abi,
      StrategyUniEthWBtcLpV1: StrategyUniEthWBtcLpV1.abi,
    },
  },
};

const BYTECODE = {
  Pickle: {
    PickleJar: PickleJar.bin,
    ControllerV3: ControllerV3.bin,
    Strategies: {
      StrategyCurve3CRVv1: StrategyCurve3CRVv1.bin,
      StrategyCurveRenCRVv1: StrategyCurveRenCRVv1.bin,
      StrategyUniEthWBtcLpV1: StrategyUniEthWBtcLpV1.bin,
    },
  },
};

module.exports = {
  ADDRESSES,
  ABIS,
  BYTECODE,
};
