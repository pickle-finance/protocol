// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaWannaNearLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_aurora_near_poolid = 8;
    // Token addresses
    address public wanna_aurora_near_lp =
        0x7E9EA10E5984a09D19D05F31ca3cB65BB7df359d;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            aurora,
            near,
            wanna_aurora_near_poolid,
            wanna_aurora_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
        swapRoutes[aurora] = [wanna, near, aurora];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaWannaNearLp";
    }
}
