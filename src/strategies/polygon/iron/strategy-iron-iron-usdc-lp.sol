// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-general-masterchef-base.sol";

contract StrategyIronIronUsdcLp is StrategyGeneralMasterChefBase {
    // Token addresses
    address public titan = 0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A;
    address public masterChef = 0x65430393358e55A658BcdE6FF69AB28cF1CbB77a;
    address public sushi_usdc_iron_lp = 0x85dE135fF062Df790A5f20B79120f17D3da63b2d;
    address public iron = 0xD86b5923F3AD7b585eD81B448170ae026c65ae9a;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
      public
      StrategyGeneralMasterChefBase(
        titan,
        masterChef,
        usdc,
        iron,
        1, // pool id
        sushi_usdc_iron_lp,
        _governance,
        _strategist,
        _controller,
        _timelock
      )
    {
      uniswapRoutes[iron] = [titan, iron];
      uniswapRoutes[usdc] = [titan, usdc];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyIronIronUsdcLp";
    }
}
