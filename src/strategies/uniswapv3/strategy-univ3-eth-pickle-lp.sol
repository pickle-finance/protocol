// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyEthPickleUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x11c4D3b9cd07807F455371d56B3899bBaE662788;
    address private pickle = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;
    address private weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(weth, priv_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        tokenToNativeRoutes[pickle] = abi.encodePacked(pickle, uint24(10000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthPickleUniV3";
    }
}
