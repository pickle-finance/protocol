// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-general-masterchef-base.sol";

contract StrategyDinoWorkUsdcLp is StrategyGeneralMasterChefBase {
    // Token addresses
    address public dino = 0xAa9654BECca45B5BDFA5ac646c939C62b527D394;
    address public masterChef = 0x1948abC5400Aa1d72223882958Da3bec643fb4E5;
    address public sushi_work_usdc_lp = 0xAb0454B98dAf4A02EA29292E6A8882FB2C787DD4;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public work = 0x6002410dDA2Fb88b4D0dc3c1D562F7761191eA80;

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
        work,
        20, // pool id
        sushi_work_usdc_lp,
        _governance,
        _strategist,
        _controller,
        _timelock
      )
    {
      uniswapRoutes[usdc] = [dino, usdc];
      uniswapRoutes[work] = [dino, usdc, work];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyDinoWorkUsdcLp";
    }
}
