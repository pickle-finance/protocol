// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriStnearNearLp is StrategyTriDualFarmBaseV2 {
    // Token/stnear pool id in MasterChef contract
    uint256 public tri_stnear_near_poolid = 12;
    // Token addresses
    address public tri_stnear_near_lp =
        0x47924Ae4968832984F4091EEC537dfF5c38948a4;
    address public stnear = 0x07F9F7f963C5cD2BBFFd30CcfB964Be114332E30;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            stnear,
            near,
            tri_stnear_near_poolid,
            tri_stnear_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[stnear] = [tri, near, stnear];
        swapRoutes[near] = [tri, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriStnearNearLp";
    }
}
