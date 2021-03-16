// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mirror-farm-base.sol";

contract StrategyMirrorQqqUstLp is StrategyMirFarmBase {
    // Token addresses
    address public qqq_rewards = 0xc1d2ca26A59E201814bF6aF633C3b3478180E91F;
    address public uni_qqq_ust_lp = 0x9E3B47B861B451879d43BBA404c35bdFb99F0a6c;
    address public mQQQ = 0x13B02c8dE71680e71F0820c996E4bE43c2F57d15;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMirFarmBase(
            mQQQ,
            qqq_rewards,
            uni_qqq_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMirrorQqqUstLp";
    }
}
