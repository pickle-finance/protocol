// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmBeetsLp is StrategyBooFarmLPBase {
    uint256 public wftm_beets_poolid = 58;
    // Token addresses
    address public wftm_beets_lp = 0x648a7452DA25B4fB4BDB79bADf374a8f8a5ea2b5;
    address public beets = 0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            wftm_beets_lp,
            wftm_beets_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[beets] = [boo, wftm, beets];
        swapRoutes[wftm] = [boo, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmBeetsLp";
    }
}
