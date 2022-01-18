// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyTriMaticNearLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public matic_near_poolid = 7;
    // Token addresses
    address public matic_near_lp = 0x3dC236Ea01459F57EFc737A12BA3Bb5F3BFfD071;
    address public matic = 0x6aB6d61428fde76768D7b45D8BFeec19c6eF91A8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
            matic,
            near,
            matic_near_poolid,
            matic_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
        swapRoutes[matic] = [tri, near, matic];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriMaticNearLp";
    }
}
