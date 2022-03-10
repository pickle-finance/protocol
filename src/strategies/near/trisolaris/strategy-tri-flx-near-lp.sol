// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriFlxNearLp is StrategyTriDualFarmBaseV2 {
    // Token/flx pool id in MasterChef contract
    uint256 public tri_flx_near_poolid = 8;
    // Token addresses
    address public tri_flx_near_lp = 0x48887cEEA1b8AD328d5254BeF774Be91B90FaA09;
    address public flx = 0xea62791aa682d455614eaA2A12Ba3d9A2fD197af;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            flx,
            near,
            tri_flx_near_poolid,
            tri_flx_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        pathExtraReward[tri] = [flx, near, tri];
        swapRoutes[flx] = [tri, near, flx];
        swapRoutes[near] = [tri, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriFlxNearLp";
    }
}
