// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyUsdtUsdcLp is StrategySolarFarmBase {
    uint256 public usdt_usdc_poolId = 13;

    // Token addresses
    address public usdt_usdc_lp = 0x2a44696DDc050f14429bd8a4A05c750C6582bF3b;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;
    address public usdt = 0xB44a9B6905aF7c801311e8F4E76932ee959c663C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            usdt,
            usdc,
            usdt_usdc_poolId,
            usdt_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [solar, usdc];
        uniswapRoutes[usdt] = [solar, usdc, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUsdtUsdcLp";
    }
}
