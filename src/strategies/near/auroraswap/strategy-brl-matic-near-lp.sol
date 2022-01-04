// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlMaticNearLp is StrategyBrlFarmBase {
    uint256 public matic_near_poolid = 12;
    // Token addresses
    address public matic_near_lp = 0x8298B8C863c2213B9698A08de009cC0aB0F87FEe;
    address public matic = 0x6aB6d61428fde76768D7b45D8BFeec19c6eF91A8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
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
        swapRoutes[near] = [brl, near];
        swapRoutes[matic] = [brl, near, matic];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlMaticNearLp";
    }
}
