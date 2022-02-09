// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmTreebLp is StrategyBooFarmLPBase {
    uint256 public ftm_treeb_poolid = 34;
    // Token addresses
    address public ftm_treeb_lp = 0xe8b72a866b8D59F5c13D2ADEF96E40A3EF5b3152;
    address public treeb = 0xc60D7067dfBc6f2caf30523a064f416A5Af52963;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            ftm_treeb_lp,
            ftm_treeb_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[treeb] = [boo, ftm, treeb];
        swapRoutes[ftm] = [boo, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmTreebLp";
    }
}
