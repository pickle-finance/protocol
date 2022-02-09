// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmIceLp is StrategyBooFarmLPBase {
    uint256 public ftm_ice_poolid = 17;
    // Token addresses
    address public ftm_ice_lp = 0x623EE4a7F290d11C11315994dB70FB148b13021d;
    address public ice = 0xf16e81dce15B08F326220742020379B855B87DF9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            ftm_ice_lp,
            ftm_ice_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[ice] = [boo, ftm, ice];
        swapRoutes[ftm] = [boo, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmIceLp";
    }
}
