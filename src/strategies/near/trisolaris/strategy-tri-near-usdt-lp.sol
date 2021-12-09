// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base.sol";

contract StrategyTriNearUsdtLp is StrategyTriFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_near_usdt_poolid = 2;
    // Token addresses
    address public tri_near_usdt_lp =
        0x03B666f3488a7992b2385B12dF7f35156d7b29cD;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            near,
            usdt,
            tri_near_usdt_poolid,
            tri_near_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
        swapRoutes[usdt] = [tri, near, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriNearUsdtLp";
    }
}
