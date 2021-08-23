
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cherry-farm-base.sol";

contract StrategyCherryUsdtUsdcLp is StrategyCherryFarmBase {
    uint256 public usdt_usdc_poolId = 23;

    // Token addresses
    address public cherry_usdt_usdc_lp = 0xb6fCc8CE3389Aa239B2A5450283aE9ea5df9d1A9;
    address public usdc = 0xc946DAf81b08146B1C7A8Da2A851Ddf2B3EAaf85;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCherryFarmBase(
            usdt,
            usdc,
            usdt_usdc_poolId,
            cherry_usdt_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [cherry, usdt, usdc];
        uniswapRoutes[usdt] = [cherry, usdt];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyCherryUsdtUsdcLp";
    }
}
