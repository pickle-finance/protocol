// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyTriUsdtTriLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public usdt_tri_poolid = 4;
    // Token addresses
    address public usdt_tri_lp = 0x61C9E05d1Cdb1b70856c7a2c53fA9c220830633c;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
            usdt,
            tri,
            usdt_tri_poolid,
            usdt_tri_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [tri, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriUsdtTriLp";
    }
}
