// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mirror-farm-base.sol";

contract StrategyMirrorMirUstLp is StrategyMirFarmBase {
    // Token addresses
    address public mir_rewards = 0x5d447Fc0F8965cED158BAB42414Af10139Edf0AF;
    address public uni_mir_ust_lp = 0x87dA823B6fC8EB8575a235A824690fda94674c88;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMirFarmBase(
            mir,
            mir_rewards,
            uni_mir_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMirrorMirUstLp";
    }
}
