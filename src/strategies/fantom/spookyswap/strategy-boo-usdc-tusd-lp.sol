// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooUsdcTusdLp is StrategyBooFarmLPBase {
    uint256 public usdc_tusd_poolid = 45;
    // Token addresses
    address public usdc_tusd_lp = 0x12692B3bf8dd9Aa1d2E721d1a79efD0C244d7d96;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public tusd = 0x9879aBDea01a879644185341F7aF7d8343556B7a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            usdc_tusd_lp,
            usdc_tusd_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [boo, wftm, usdc];
        swapRoutes[tusd] = [boo, wftm, usdc, tusd];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooUsdcTusdLp";
    }
}
