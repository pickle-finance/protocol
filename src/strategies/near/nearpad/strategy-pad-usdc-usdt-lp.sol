// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadUsdtUsdcLp is StrategyNearPadFarmBase {
    uint256 public usdt_usdc_poolid = 6;
    // Token addresses
    address public usdt_usdc_lp = 0x9f31f2cFd64cEbFe021f0102E17c7Ae1c76CCb6b;
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
            usdt,
            usdc,
            usdt_usdc_poolid,
            usdt_usdc_lp,
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
        return "StrategyPadUsdtUsdcLp";
    }
}
