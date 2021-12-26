// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance.sol";

contract StrategyMaticEthUniV3Poly is StrategyRebalanceUniV3 {
    address public matic_eth_pool = 0x167384319B41F7094e62f7506409Eb38079AbfF8;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(matic_eth_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock){ }

    function getName() external pure override returns (string memory) {
        return "StrategyMaticEthUniV3Poly";
    }
}
