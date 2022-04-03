// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadNearFraxLp is StrategyNearPadFarmBase {
    uint256 public near_frax_poolid = 15;
    // Token addresses
    address public near_frax_lp = 0xac187A18f9DaB50506fc8111aa7E86F5F55DefE9;
    address public frax = 0xDA2585430fEf327aD8ee44Af8F1f989a2A91A3d2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            near,
            frax,
            near_frax_poolid,
            near_frax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [pad, near];
        swapRoutes[frax] = [pad, near, frax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadNearFraxLp";
    }
}
