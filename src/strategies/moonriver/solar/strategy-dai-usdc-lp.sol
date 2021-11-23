// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyDaiUsdcLp is StrategySolarFarmBase {
    uint256 public dai_usdc_poolId = 5;

    // Token addresses
    address public dai_usdc_lp = 0xFE1b71BDAEE495dCA331D28F5779E87bd32FbE53;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;
    address public dai = 0x80A16016cC4A2E6a2CACA8a4a498b1699fF0f844;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            dai,
            usdc,
            dai_usdc_poolId,
            dai_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [solar, usdc];
        uniswapRoutes[dai] = [solar, usdc, dai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyDaiUsdcLp";
    }
}
