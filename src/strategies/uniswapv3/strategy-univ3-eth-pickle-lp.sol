// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyEthPickleUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x11c4D3b9cd07807F455371d56B3899bBaE662788;

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
        return "StrategyEthPickleUniV3";
    }
}
