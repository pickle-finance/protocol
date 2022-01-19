// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyVVSUsdtLp is StrategyVVSFarmBase {
    uint256 public vvs_usdt_poolId = 7;

    // Token addresses
    address public vvs_usdt_lp = 0x280aCAD550B2d3Ba63C8cbff51b503Ea41a1c61B;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            vvs,
            usdt,
            vvs_usdt_poolId,
            vvs_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [vvs, usdt];
        // uniswapRoutes[vvs] = [vvs, vvs];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVVSUsdtLp";
    }
}
