// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-general-masterchef-base.sol";

contract StrategyDinoDinoUsdcLp is StrategyGeneralMasterChefBase {
    // Token addresses
    address public dino = 0xAa9654BECca45B5BDFA5ac646c939C62b527D394;
    address public masterChef = 0x1948abC5400Aa1d72223882958Da3bec643fb4E5;
    address public sushi_usdc_dino_lp = 0x3324af8417844e70b81555A6D1568d78f4D4Bf1f;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
      public
      StrategyGeneralMasterChefBase(
        dino,
        masterChef,
        usdc,
        dino,
        10, // pool id
        sushi_usdc_dino_lp,
        _governance,
        _strategist,
        _controller,
        _timelock
      )
    {
      uniswapRoutes[usdc] = [dino, usdc];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyDinoDinoUsdcLp";
    }
}
