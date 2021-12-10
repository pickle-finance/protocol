// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base.sol";

contract StrategyTriUsdcUsdtLp is StrategyTriFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_usdc_usdt_poolid = 3;
    // Token addresses
    address public tri_usdc_usdt_lp =
        0x2fe064B6c7D274082aa5d2624709bC9AE7D16C77;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            usdc,
            usdt,
            tri_usdc_usdt_poolid,
            tri_usdc_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [tri, near, usdt];
        swapRoutes[usdc] = [tri, near, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriUsdcUsdtLp";
    }
}
