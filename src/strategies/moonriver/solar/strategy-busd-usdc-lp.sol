// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyBusdUsdcLp is StrategySolarFarmBase {
    uint256 public busd_usdc_poolId = 9;

    // Token addresses
    address public busd_usdc_lp = 0x384704557F73fBFAE6e9297FD1E6075FC340dbe5;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;
    address public busd = 0x5D9ab5522c64E1F6ef5e3627ECCc093f56167818;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            busd,
            usdc,
            busd_usdc_poolId,
            busd_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [solar, usdc];
        uniswapRoutes[busd] = [solar, usdc, busd];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBusdUsdcLp";
    }
}
