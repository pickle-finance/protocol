// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-finn-farm-base.sol";

contract StrategyFinnUsdcMovrLp is StrategyFinnFarmBase {
    uint256 public usdc_movr_poolId = 28;

    // Token addresses
    address public usdc_movr_lp = 0x7128C61Da34c27eAD5419B8EB50c71CE0B15CD50;
    address public usdc = 0x748134b5F553F2bcBD78c6826De99a70274bDEb3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFinnFarmBase(
            usdc,
            movr,
            usdc_movr_poolId,
            usdc_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[movr] = [finn, movr];
        uniswapRoutes[usdc] = [finn, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFinnUsdcMovrLp";
    }
}
