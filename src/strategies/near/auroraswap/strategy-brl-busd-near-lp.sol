// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlBusdNearLp is StrategyBrlFarmBase {
    uint256 public busd_near_poolid = 10;
    // Token addresses
    address public busd_near_lp = 0x1C393468D95ADF8960E64939bCDd6eE602DE221C;
    address public busd = 0x5D9ab5522c64E1F6ef5e3627ECCc093f56167818;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            busd,
            near,
            busd_near_poolid,
            busd_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[busd] = [brl, near, busd];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlBusdNearLp";
    }
}
