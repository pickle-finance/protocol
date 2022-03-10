// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriRoseNearLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_rose_near_poolid = 20;
    // Token addresses
    address public tri_rose_near_lp =
        0xbe753E99D0dBd12FB39edF9b884eBF3B1B09f26C;
    address public rose = 0xdcD6D4e2B3e1D1E1E6Fa8C21C8A323DcbecfF970;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            rose,
            tri_rose_near_poolid,
            tri_rose_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = rose;
        swapRoutes[rose] = [tri, near, rose];
        swapRoutes[near] = [rose, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriRoseNearLp";
    }
}
