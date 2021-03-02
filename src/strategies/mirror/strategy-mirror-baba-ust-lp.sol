// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mirror-farm-base.sol";

contract StrategyMirrorBabaUstLp is StrategyMirFarmBase {
    // Token addresses
    address public baba_rewards = 0x769325E8498bF2C2c3cFd6464A60fA213f26afcc;
    address public uni_baba_ust_lp = 0x676Ce85f66aDB8D7b8323AeEfe17087A3b8CB363;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMirFarmBase(
            mir,
            baba_rewards,
            uni_baba_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMirrorBabaUstLp";
    }
}
