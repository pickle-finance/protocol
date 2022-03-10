// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriAuroraNearLp is StrategyTriDualFarmBaseV2 {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_aurora_near_poolid = 24;
    // Token addresses
    address public tri_aurora_near_lp =
        0x1e0e812FBcd3EB75D8562AD6F310Ed94D258D008;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            aurora,
            tri_aurora_near_poolid,
            tri_aurora_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = aurora;
        swapRoutes[aurora] = [tri, aurora];
        swapRoutes[near] = [aurora, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriAuroraNearLp";
    }
}
