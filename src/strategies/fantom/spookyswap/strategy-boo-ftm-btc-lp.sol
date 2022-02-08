// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmBtcLp is StrategyBooFarmLPBase {
    uint256 public ftm_btc_poolid = 4;
    // Token addresses
    address public ftm_btc_lp = 0x321162Cd933E2Be498Cd2267a90534A804051b11;
    address public btc = 0x321162Cd933E2Be498Cd2267a90534A804051b11;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            ftm_btc_lp,
            ftm_btc_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[ftm] = [boo, ftm];
        swapRoutes[btc] = [boo, ftm, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmBtcLp";
    }
}
