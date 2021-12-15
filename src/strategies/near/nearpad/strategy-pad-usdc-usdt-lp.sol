// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadUsdcUsdtLp is StrategyNearPadFarmBase {
    uint256 public usdc_usdt_poolid = 6;
    // Token addresses
    address public usdc_usdt_lp = 0x9f31f2cFd64cEbFe021f0102E17c7Ae1c76CCb6b;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            usdc,
            usdt,
            usdc_usdt_poolid,
            usdc_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [pad, usdc];
        swapRoutes[usdt] = [pad, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadUsdcUsdtLp";
    }
}
