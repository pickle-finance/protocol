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

const ABIS = {
  Pickle: {
    PickleJar: DAPP_CONTRACTS["src/pickle-jar.sol:PickleJar"].abi,
    ControllerV3: DAPP_CONTRACTS["src/controller-v3.sol:ControllerV3"].abi,
    Strategies: {
      Curve: {
        StrategyCurveSCRVv4:
          DAPP_CONTRACTS[
            "src/strategies/curve/strategy-curve-scrv-v4.sol:StrategyCurveSCRVv4"
          ].abi,
        StrategyCurveSCRVv3:
          DAPP_CONTRACTS[
            "src/strategies/curve/strategy-curve-scrv-v3.sol:StrategyCurveSCRVv3"
          ].abi,
        SCRVVoter:
          DAPP_CONTRACTS["src/strategies/curve/scrv-voter.sol:SCRVVoter"].abi,
        CRVLocker:
          DAPP_CONTRACTS["src/strategies/curve/crv-locker.sol:CRVLocker"].abi,
      },
      UniswapV2: {
        StrategyUniEthDaiLpV3:
          DAPP_CONTRACTS[
            "src/strategies/uniswapv2/strategy-uni-eth-dai-lp-v3.sol:StrategyUniEthDaiLpV3"
          ].abi,
        StrategyUniEthUsdcLpV3:
          DAPP_CONTRACTS[
            "src/strategies/uniswapv2/strategy-uni-eth-usdc-lp-v3.sol:StrategyUniEthUsdcLpV3"
          ].abi,
        StrategyUniEthUsdtLpV3:
          DAPP_CONTRACTS[
            "src/strategies/uniswapv2/strategy-uni-eth-usdt-lp-v3.sol:StrategyUniEthUsdtLpV3"
          ].abi,
      },
    },
  },
  CurveFi: {
    VotingEscrow:
      DAPP_CONTRACTS["src/interfaces/curve.sol:ICurveVotingEscrow"].abi,
    GaugeController: DAPP_CONTRACTS["src/interfaces/curve.sol:ICurveGauge"].abi,
    SmartContractChecker:
      DAPP_CONTRACTS["src/interfaces/curve.sol:ICurveSmartContractChecker"].abi,
  },
  UniswapV2: {
    Router2: DAPP_CONTRACTS["src/interfaces/uniswapv2.sol:UniswapRouterV2"].abi,
  },
  ERC20: DAPP_CONTRACTS["src/lib/erc20.sol:IERC20"].abi,
};

const BYTECODE = {
  Pickle: {
    PickleJar: DAPP_CONTRACTS["src/pickle-jar.sol:PickleJar"].bin,
    ControllerV3: DAPP_CONTRACTS["src/controller-v3.sol:ControllerV3"].bin,
    Strategies: {
      Curve: {
        StrategyCurveSCRVv4:
          DAPP_CONTRACTS[
            "src/strategies/curve/strategy-curve-scrv-v4.sol:StrategyCurveSCRVv4"
          ].bin,
        StrategyCurveSCRVv3:
          DAPP_CONTRACTS[
            "src/strategies/curve/strategy-curve-scrv-v3.sol:StrategyCurveSCRVv3"
          ].bin,
        SCRVVoter:
          DAPP_CONTRACTS["src/strategies/curve/scrv-voter.sol:SCRVVoter"].bin,
        CRVLocker:
          DAPP_CONTRACTS["src/strategies/curve/crv-locker.sol:CRVLocker"].bin,
      },
      UniswapV2: {
        StrategyUniEthDaiLpV3:
          DAPP_CONTRACTS[
            "src/strategies/uniswapv2/strategy-uni-eth-dai-lp-v3.sol:StrategyUniEthDaiLpV3"
          ].bin,
        StrategyUniEthUsdcLpV3:
          DAPP_CONTRACTS[
            "src/strategies/uniswapv2/strategy-uni-eth-usdc-lp-v3.sol:StrategyUniEthUsdcLpV3"
          ].bin,
        StrategyUniEthUsdtLpV3:
          DAPP_CONTRACTS[
            "src/strategies/uniswapv2/strategy-uni-eth-usdt-lp-v3.sol:StrategyUniEthUsdtLpV3"
          ].bin,
      },
    },
  },
};

module.exports = {
  ADDRESSES,
  ABIS,
  BYTECODE,
};
