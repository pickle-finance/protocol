// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyUsdtPadLp is StrategyNearPadFarmBase {
    uint256 public usdt_pad_poolid = 0;
    // Token addresses
    address public usdt_pad_lp = 0x1FD6CBBFC0363AA394bd77FC74F64009BF54A7e9;
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
            pad,
            usdt_pad_poolid,
            usdt_pad_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [pad, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUsdtPadLp";
    }
}
