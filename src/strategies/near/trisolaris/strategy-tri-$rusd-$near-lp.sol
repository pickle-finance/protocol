// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriRusdNearLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_rusd_near_poolid = 21;
    // Token addresses
    address public tri_rusd_near_lp =
        0xbC0e71aE3Ef51ae62103E003A9Be2ffDe8421700;
    address public rose = 0xdcD6D4e2B3e1D1E1E6Fa8C21C8A323DcbecfF970;
    address public rusd = 0x19cc40283B057D6608C22F1D20F17e16C245642E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            rose,
            tri_rusd_near_poolid,
            tri_rusd_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraReward = rose;
        swapRoutes[tri] = [rose, near, tri];
        swapRoutes[rusd] = [tri, near, rusd];
        swapRoutes[near] = [tri, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriRusdNearLp";
    }
}
