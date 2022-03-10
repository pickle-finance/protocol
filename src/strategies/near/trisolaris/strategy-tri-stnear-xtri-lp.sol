// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriStnearXtriLp is StrategyTriDualFarmBaseV2 {
    // Token/stnear pool id in MasterChef contract
    uint256 public tri_stnear_xtri_poolid = 11;
    // Token addresses
    address public tri_stnear_xtri_lp =
        0x48887cEEA1b8AD328d5254BeF774Be91B90FaA09;
    address public stnear = 0x07F9F7f963C5cD2BBFFd30CcfB964Be114332E30;
    address public xtri = 0x802119e4e253D5C19aA06A5d567C5a41596D6803;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            stnear,
            xtri,
            tri_stnear_xtri_poolid,
            tri_stnear_xtri_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[stnear] = [tri, near, stnear];
        swapRoutes[xtri] = [tri, near, stnear, xtri];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriStnearXtriLp";
    }
}
