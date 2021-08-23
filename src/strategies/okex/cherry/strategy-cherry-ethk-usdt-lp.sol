
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cherry-farm-base.sol";

contract StrategyCherryEthkUsdtLp is StrategyCherryFarmBase {
    uint256 public ethk_usdt_poolId = 5;

    // Token addresses
    address public cherry_ethk_usdt_lp = 0x407F7a2F61E5bAB199F7b9de0Ca330527175Da93;
    address public ethk = 0xEF71CA2EE68F45B9Ad6F72fbdb33d707b872315C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCherryFarmBase(
            ethk,
            usdt,
            ethk_usdt_poolId,
            cherry_ethk_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [cherry, usdt];
        uniswapRoutes[ethk] = [cherry, usdt, ethk];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyCherryEthkUsdtLp";
    }
}
