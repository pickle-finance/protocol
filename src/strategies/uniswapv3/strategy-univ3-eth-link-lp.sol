// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyEthLinkUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0xa6Cc3C2531FdaA6Ae1A3CA84c2855806728693e8;

    constructor(
        int24 _tickRangeMultiplier,
        uint24 _swapPoolFee,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyRebalanceUniV3(priv_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock) {
        swapPoolFee = (_swapPoolFee != 0) ? _swapPoolFee : pool.fee();
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthLinkUniV3";
    }
}
