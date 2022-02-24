// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyUsdcEth3UniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;

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
        return "StrategyUsdcEth3UniV3";
    }
}
