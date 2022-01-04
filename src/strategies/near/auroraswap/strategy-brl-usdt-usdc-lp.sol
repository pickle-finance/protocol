// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlUsdtUsdcLp is StrategyBrlFarmBase {
    uint256 public usdt_near_poolid = 2;
    // Token addresses
    address public usdt_near_lp = 0xEc538fAfaFcBB625C394c35b11252cef732368cd;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            usdt,
            near,
            usdt_near_poolid,
            usdt_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [brl, near, usdt];
        swapRoutes[usdc] = [brl, near, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlUsdtUsdcLp";
    }
}
