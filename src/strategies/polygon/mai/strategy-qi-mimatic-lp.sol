// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-general-masterchef-base.sol";

contract StrategyMaiQiMiMaticLp is StrategyGeneralMasterChefBase {
    // Token addresses
    address public qi = 0x580A84C73811E1839F75d86d75d88cCa0c241fF4;
    address public masterChef = 0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F;
    address public sushi_qi_mimatic_lp = 0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397;
    address public mimatic = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
    address public quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
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
        qi,
        mimatic,
        2, // pool id
        sushi_qi_mimatic_lp,
        _governance,
        _strategist,
        _controller,
        _timelock
      )
    {
      uniswapRoutes[mimatic] = [qi, mimatic];
      sushiRouter = quickRouter; // use quickswap router instead of sushi router
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMaiQiMiMaticLp";
    }

    function getHarvestable() external override view returns (uint256) {
        uint256 _pendingReward = IMasterchef(masterchef).pending(poolId, address(this));
        return _pendingReward;
    }
}
