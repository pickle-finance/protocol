// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmBtcLp is StrategyBooFarmLPBase {
    uint256 public wftm_btc_poolid = 4;
    // Token addresses
    address public wftm_btc_lp = 0xFdb9Ab8B9513Ad9E419Cf19530feE49d412C3Ee3;
    address public btc = 0x321162Cd933E2Be498Cd2267a90534A804051b11;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            wftm_btc_lp,
            wftm_btc_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[wftm] = [boo, wftm];
        swapRoutes[btc] = [boo, wftm, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmBtcLp";
    }
}
