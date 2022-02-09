// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmAnyLp is StrategyBooFarmLPBase {
    uint256 public ftm_any_poolid = 22;
    // Token addresses
    address public ftm_any_lp = 0x5c021D9cfaD40aaFC57786b409A9ce571de375b4;
    address public any = 0xdDcb3fFD12750B45d32E084887fdf1aABAb34239;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            ftm_any_lp,
            ftm_any_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[any] = [boo, ftm, any];
        swapRoutes[ftm] = [boo, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmAnyLp";
    }
}
