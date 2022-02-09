// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooUsdtFtmLp is StrategyBooFarmLPBase {
    uint256 public usdt_wftm_poolid = 1;
    // Token addresses
    address public usdt_wftm_lp = 0x5965E53aa80a0bcF1CD6dbDd72e6A9b2AA047410;
    address public usdt = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            usdt_wftm_lp,
            usdt_wftm_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [boo, wftm, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooUsdtFtmLp";
    }
}
