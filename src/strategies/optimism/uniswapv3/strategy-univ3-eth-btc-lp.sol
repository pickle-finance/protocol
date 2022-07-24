// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance.sol";

contract StrategyEthBtcUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x73B14a78a0D396C521f954532d43fd5fFe385216;

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
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthBtcUniV3Optimism";
    }
}
