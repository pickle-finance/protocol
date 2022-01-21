// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaStellaUsdcLp is StrategyStellaFarmBase {
    uint256 public usdc_stella_poolId = 6;

    // Token addresses
    address public usdc_stella_lp = 0x81e11a9374033d11Cc7e7485A7192AE37D0795D6;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            usdc_stella_lp,
            usdc_stella_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [stella, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaStellaUsdcLp";
    }
}
