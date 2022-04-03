// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooUsdcFtmLp is StrategyBooFarmLPBase {
    uint256 public usdc_wftm_poolid = 2;
    // Token addresses
    address public usdc_wftm_lp = 0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            usdc_wftm_lp,
            usdc_wftm_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [boo, wftm, usdc];
        swapRoutes[wftm] = [boo, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooUsdcFtmLp";
    }
}
