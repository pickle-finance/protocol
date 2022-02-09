// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-xtoken-farm-base.sol";

contract StrategyOxdXcredit is StrategyOxdXtokenFarmBase {
    // Token addresses
    address public xcredit = 0xd9e28749e80D867d5d14217416BFf0e668C10645;
    address public credit = 0x77128DFdD0ac859B33F44050c6fa272F34872B5E;
    uint256 public xcredit_poolId = 11;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdXtokenFarmBase(
            xcredit,
            credit,
            xcredit_poolId,
            "deposit(uint256)",
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[credit] = [oxd, usdc, wftm, credit];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdXcredit";
    }
}
