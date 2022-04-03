// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyTriAuroraLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_aurora_poolid = 1;
    // Token addresses
    address public tri_aurora_lp = 0xd1654a7713617d41A8C9530Fb9B948d00e162194;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
            tri,
            aurora,
            tri_aurora_poolid,
            tri_aurora_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[aurora] = [tri, aurora];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriAuroraLp";
    }
}
