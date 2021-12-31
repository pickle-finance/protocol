// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlUsdtNearLp is StrategyBrlFarmBase {
    uint256 public usdt_near_poolid = 4;
    // Token addresses
    address public usdt_near_lp = 0xF3DE9dc38f62608179c45fE8943a0cA34Ba9CEfc;
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
            near,
            usdt_near_poolid,
            usdt_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[usdt] = [brl, near, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlUsdtNearLp";
    }
}
