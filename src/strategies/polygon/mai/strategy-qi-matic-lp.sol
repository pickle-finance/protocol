// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-general-masterchef-base.sol";

contract StrategyMaiQiMaticLp is StrategyGeneralMasterChefBase {
    // Token addresses
    address public qi = 0x580A84C73811E1839F75d86d75d88cCa0c241fF4;
    address public masterChef = 0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F;
    address public quick_qi_wmatic_lp = 0x9A8b2601760814019B7E6eE0052E25f1C623D1E6;
    address public quickRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
      public
      StrategyGeneralMasterChefBase(
        qi,
        masterChef,
        wmatic,
        qi,
        3, // pool id
        quick_qi_wmatic_lp,
        _governance,
        _strategist,
        _controller,
        _timelock
      )
    {
      uniswapRoutes[wmatic] = [qi, wmatic];
      sushiRouter = quickRouter; // use quickswap router instead of sushi router
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMaiQiMaticLp";
    }

    function getHarvestable() external override view returns (uint256) {
        uint256 _pendingReward = IMasterchef(masterchef).pending(poolId, address(this));
        return _pendingReward;
    }
}
