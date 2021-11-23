// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategySolarUsdcLp is StrategySolarFarmBase {
    uint256 public solar_usdc_poolId = 7;

    // Token addresses
    address public solar_usdc_lp = 0xdb66BE1005f5Fe1d2f486E75cE3C50B52535F886;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            solar,
            usdc,
            solar_usdc_poolId,
            solar_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [solar, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySolarUsdcLp";
    }
}
