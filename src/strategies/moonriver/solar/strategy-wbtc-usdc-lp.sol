// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyWbtcUsdcLp is StrategySolarFarmBase {
    uint256 public wbtc_usdc_poolId = 10;

    // Token addresses
    address public wbtc_usdc_lp = 0x83d7a3fc841038E8c8F46e6192BBcCA8b19Ee4e7;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;
    address public wbtc = 0x6aB6d61428fde76768D7b45D8BFeec19c6eF91A8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            wbtc,
            usdc,
            wbtc_usdc_poolId,
            wbtc_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[wbtc] = [solar, usdc, wbtc];
        uniswapRoutes[usdc] = [solar, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWbtcUsdcLp";
    }
}
