// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mirror-farm-base.sol";

contract StrategyMirrorSlvUstLp is StrategyMirFarmBase {
    // Token addresses
    address public slv_rewards = 0xDB278fb5f7d4A7C3b83F80D18198d872Bbf7b923;
    address public uni_slv_ust_lp = 0x860425bE6ad1345DC7a3e287faCBF32B18bc4fAe;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMirFarmBase(
            mir,
            slv_rewards,
            uni_slv_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMirrorSlvUstLp";
    }
}
