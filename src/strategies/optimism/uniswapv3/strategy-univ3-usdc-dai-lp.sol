// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance.sol";

contract StrategyUsdcDaiUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x100bdC1431A9b09C61c0EFC5776814285f8fB248;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(priv_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        performanceTreasuryFee = 1000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcDaiUniV3Optimism";
    }
}
