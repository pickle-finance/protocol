// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyMovrFtmLp is StrategySolarFarmBase {
    uint256 public movr_ftm_poolId = 18;

    // Token addresses
    address public movr_ftm_lp = 0x1eebed8F28A6865a76D91189FD6FC45F4F774d67;
    address public ftm = 0xaD12daB5959f30b9fF3c2d6709f53C335dC39908;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            movr,
            ftm,
            movr_ftm_poolId,
            movr_ftm_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[movr] = [solar, movr];
        uniswapRoutes[ftm] = [solar, movr, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMovrFtmLp";
    }
}
