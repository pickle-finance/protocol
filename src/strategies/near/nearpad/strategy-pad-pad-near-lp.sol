// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadPadNearLp is StrategyNearPadFarmBase {
    uint256 public pad_near_poolid = 5;
    // Token addresses
    address public pad_near_lp = 0xc374776Cf5C497Adeef6b505588b00cB298531FD;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            near,
            pad_near_poolid,
            pad_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [pad, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadPadNearLp";
    }
}
