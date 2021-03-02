// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mirror-farm-base.sol";

contract StrategyMirrorTslaUstLp is StrategyMirFarmBase {
    // Token addresses
    address public tsla_rewards = 0x43DFb87a26BA812b0988eBdf44e3e341144722Ab;
    address public uni_tsla_ust_lp = 0x5233349957586A8207c52693A959483F9aeAA50C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMirFarmBase(
            mir,
            tsla_rewards,
            uni_tsla_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMirrorTslaUstLp";
    }
}
