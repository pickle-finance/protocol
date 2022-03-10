// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyNearLunaLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public near_luna_poolid = 2;
    // Token addresses
    address public near_luna_lp = 0xdF8CbF89ad9b7dAFdd3e37acEc539eEcC8c47914;
    address public luna = 0xC4bdd27c33ec7daa6fcfd8532ddB524Bf4038096;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
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
        swapRoutes[luna] = [tri, near, luna];
        swapRoutes[near] = [tri, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNearLunaLp";
    }
}
