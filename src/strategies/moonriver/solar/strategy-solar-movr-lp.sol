// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategySolarMovrLp is StrategySolarFarmBase {
    uint256 public solar_movr_poolId = 0;

    // Token addresses
    address public solar_movr_lp =  0x7eDA899b3522683636746a2f3a7814e6fFca75e1;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            solar,
            movr,
            solar_movr_poolId,
            solar_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[movr] = [solar, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySolarMovrLp";
    }
}
