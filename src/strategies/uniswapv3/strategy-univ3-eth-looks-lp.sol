// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyEthLooksUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x4b5Ab61593A2401B1075b90c04cBCDD3F87CE011;

    constructor(
        int24 _tickRangeMultiplier,
        uint24 _swapPoolFee,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(
            priv_pool,
            _tickRangeMultiplier,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapPoolFee = (_swapPoolFee != 0) ? _swapPoolFee : pool.fee();
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthLooksUniV3";
    }
}
