// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlAuroraNearLp is StrategyBrlFarmBase {
    uint256 public aurora_near_poolid = 16;
    // Token addresses
    address public aurora_near_lp = 0x84567E7511E0d97DE676d236AEa7aE688221799e;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            aurora,
            near,
            aurora_near_poolid,
            aurora_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[aurora] = [brl, aurora];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlAuroraNearLp";
    }
}
f