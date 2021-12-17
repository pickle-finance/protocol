// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyMaiUsdcLp is StrategySolarFarmBase {
    uint256 public mai_usdc_poolId = 17;

    // Token addresses
    address public mai_usdc_lp = 0x55Ee073B38BF1069D5F1Ed0AA6858062bA42F5A9;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;
    address public mai = 0x7f5a79576620C046a293F54FFCdbd8f2468174F1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            mai,
            usdc,
            mai_usdc_poolId,
            mai_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [solar, usdc];
        uniswapRoutes[mai] = [solar, usdc, mai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMaiUsdcLp";
    }
}
