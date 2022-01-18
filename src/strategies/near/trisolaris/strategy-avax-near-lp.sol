// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyAvaxNearLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public avax_near_poolid = 5;
    // Token addresses
    address public avax_near_lp = 0x6443532841a5279cb04420E61Cf855cBEb70dc8C;
    address public avax = 0x80A16016cC4A2E6a2CACA8a4a498b1699fF0f844;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
            avax,
            near,
            avax_near_poolid,
            avax_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
        swapRoutes[avax] = [tri, near, avax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyAvaxNearLp";
    }
}
