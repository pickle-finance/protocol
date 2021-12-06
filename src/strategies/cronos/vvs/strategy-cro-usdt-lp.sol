// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cronos-farm-base.sol";

contract StrategyCroUsdtLp is StrategyVVSFarmBase {
    uint256 public cro_usdt_poolId = 9;

    // Token addresses
    address public cro_usdt_lp = 0x3d2180DB9E1B909f35C398BC39EF36108C0FC8c3;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
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
        uniswapRoutes[usdt] = [vvs, usdt];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroUsdtLp";
    }
}
