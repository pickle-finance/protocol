// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base.sol";

contract StrategyTriTriNearLp is StrategyTriFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_tri_near_poolid = 1;
    // Token addresses
    address public tri_tri_near_lp = 0x84b123875F0F36B966d0B6Ca14b31121bd9676AD;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            tri,
            near,
            tri_tri_near_poolid,
            tri_tri_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriTriNearLp";
    }
}
