// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmBnbLp is StrategyBooFarmLPBase {
    uint256 public wftm_bnb_poolid = 19;
    // Token addresses
    address public wftm_bnb_lp = 0x956DE13EA0FA5b577E4097Be837BF4aC80005820;
    address public bnb = 0xD67de0e0a0Fd7b15dC8348Bb9BE742F3c5850454;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            wftm_bnb_lp,
            wftm_bnb_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[bnb] = [boo, wftm, bnb];
        swapRoutes[wftm] = [boo, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmBnbLp";
    }
}
