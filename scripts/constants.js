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
    ControllerV3: "src/controller-v3.sol:ControllerV3",
    Strategies: {
      StrategyCmpdDaiV1:
        "src/strategies/compound/strategy-cmpd-dai-v1.sol:StrategyCmpdDaiV1",
    },
  },
};

const PickleJar = DAPP_CONTRACTS[KEYS.Pickle.PickleJar];
const ControllerV3 = DAPP_CONTRACTS[KEYS.Pickle.ControllerV3];
const StrategyCmpdDaiV1 =
  DAPP_CONTRACTS[KEYS.Pickle.Strategies.StrategyCmpdDaiV1];

const ABIS = {
  Pickle: {
    PickleJar: PickleJar.abi,
    ControllerV3: ControllerV3.abi,
    Strategies: {
      StrategyCmpdDaiV1: StrategyCmpdDaiV1.abi,
    },
  },
  UniswapV2: {
    Router2: DAPP_CONTRACTS["src/interfaces/uniswapv2.sol:UniswapRouterV2"].abi,
  },
};

const BYTECODE = {
  Pickle: {
    PickleJar: PickleJar.bin,
    ControllerV3: ControllerV3.bin,
    Strategies: {
      StrategyCmpdDaiV1: StrategyCmpdDaiV1.bin,
    },
  },
};

console.log(ABIS.Pickle.Strategies.StrategyCmpdDaiV1)

module.exports = {
  KEYS,
  ADDRESSES,
  ABIS,
  BYTECODE,
};
