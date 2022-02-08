// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooUsdcMaiLp is StrategyBooFarmLPBase {
    uint256 public usdc_mai_poolid = 42;
    // Token addresses
    address public usdc_mai_lp = 0x4dE9f0ED95de2461B6dB1660f908348c42893b1A;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public mai = 0xfB98B335551a418cD0737375a2ea0ded62Ea213b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            usdc_mai_lp,
            usdc_mai_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [boo, ftm, usdc];
        swapRoutes[mai] = [boo, ftm, usdc, mai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooUsdcMaiLp";
    }
}
