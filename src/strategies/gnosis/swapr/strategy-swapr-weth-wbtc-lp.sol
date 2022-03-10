// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-swapr-base.sol";

contract StrategySwaprWethWbtcLp is StrategySwaprFarmBase {
    // Token addresses
    address public swapr_weth_wbtc_lp = 0xf6Be7AD58F4BAA454666b0027839a01BcD721Ac3;
    address public wbtc = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySwaprFarmBase(rewarder, swapr_weth_wbtc_lp, _governance, _strategist, _controller, _timelock) {
        rewarder = 0x60eC5c7Ddfe17203c706D7082224f67d0e005fcC;
        swapRoutes[gno] = [swapr, xdai, gno];
        swapRoutes[weth] = [gno, weth];
        swapRoutes[wbtc] = [gno, weth, wbtc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprWethWbtcLp";
    }
}
