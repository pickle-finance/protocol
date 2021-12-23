// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCroUsdtLp is StrategyCronaFarmBase {
    uint256 public cro_usdt_poolId = 3;

    // Token addresses
    address public cro_usdt_lp = 0x19Dd1683e8c5F6Cc338C1438f2D25EBb4e0b0b08;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            cro,
            usdt,
            cro_usdt_poolId,
            cro_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [crona, usdt];
        uniswapRoutes[cro] = [crona, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCroUsdtLp";
    }
}
