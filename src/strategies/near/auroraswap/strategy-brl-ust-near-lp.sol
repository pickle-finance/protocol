// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlUstNearLp is StrategyBrlFarmBase {
    uint256 public ust_near_poolid = 8;
    // Token addresses
    address public ust_near_lp = 0x729dB9dB6d3cA82EF7e4c886C352749758BaD0eb;
    address public ust = 0x5ce9F0B6AFb36135b5ddBF11705cEB65E634A9dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            ust,
            near,
            ust_near_poolid,
            ust_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[ust] = [brl, near, ust];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlUstNearLp";
    }
}
