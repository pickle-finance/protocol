// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyMovrUsdcLp is StrategySolarFarmBase {
    uint256 public movr_usdc_poolId = 6;

    // Token addresses
    address public movr_usdc_lp = 0xe537f70a8b62204832B8Ba91940B77d3f79AEb81;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            movr,
            usdc,
            movr_usdc_poolId,
            movr_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[movr] = [solar, movr];
        uniswapRoutes[usdc] = [solar, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMovrUsdcLp";
    }
}
