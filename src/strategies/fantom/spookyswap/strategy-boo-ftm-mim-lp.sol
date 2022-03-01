// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmMimLp is StrategyBooFarmLPBase {
    uint256 public wftm_mim_poolid = 24;
    // Token addresses
    address public wftm_mim_lp = 0x6f86e65b255c9111109d2D2325ca2dFc82456efc;
    address public mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            wftm_mim_lp,
            wftm_mim_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[mim] = [boo, wftm, mim];
        swapRoutes[wftm] = [boo, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmMimLp";
    }
}
