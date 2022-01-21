// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaUsdcUsdtLp is StrategyStellaFarmBase {
    uint256 public usdc_usdt_poolId = 2;

    // Token addresses
    address public usdc_usdt_lp = 0x8BC3CceeF43392B315dDD92ba30b435F79b66b9e;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;
    address public usdt = 0xeFAeeE334F0Fd1712f9a8cc375f427D9Cdd40d73;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            usdc_usdt_lp,
            usdc_usdt_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [stella, usdc];
        swapRoutes[usdt] = [stella, usdc, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaUsdcUsdtLp";
    }
}
