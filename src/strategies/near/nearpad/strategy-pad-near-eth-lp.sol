// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadNearEthLp is StrategyNearPadFarmBase {
    uint256 public near_eth_poolid = 9;
    // Token addresses
    address public near_eth_lp = 0x24886811d2d5E362FF69109aed0A6EE3EeEeC00B;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            near,
            eth,
            near_eth_poolid,
            near_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [pad, eth];
        swapRoutes[near] = [pad, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadNearEthLp";
    }
}
