// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-cometh-farm-base.sol";

contract StrategyComethWmaticMustLpV4 is StrategyComethFarmBase {
    // Token addresses
    address public cometh_rewards = 0x2328c83431a29613b1780706E0Af3679E3D04afd;
    address public cometh_wmatic_must_lp = 0x80676b414a905De269D0ac593322Af821b683B92;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyComethFarmBase(
            cometh_rewards,
            cometh_wmatic_must_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyComethWmaticMustLpV4";
    }
}
