// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlNearLunaLp is StrategyBrlFarmBase {
    uint256 public near_luna_poolid = 7;
    // Token addresses
    address public near_luna_lp = 0x388D5EE199aC8dAD049B161b57487271Cd787941;
    address public luna = 0xC4bdd27c33ec7daa6fcfd8532ddB524Bf4038096;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            near,
            luna,
            near_luna_poolid,
            near_luna_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[luna] = [brl, near, luna];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlNearLunaLp";
    }
}
