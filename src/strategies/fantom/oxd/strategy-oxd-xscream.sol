// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-xtoken-farm-base.sol";

contract StrategyOxdXscream is StrategyOxdXtokenFarmBase {
    // Token addresses
    address public xscream = 0xe3D17C7e840ec140a7A51ACA351a482231760824;
    address public scream = 0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475;
    uint256 public xscream_poolId = 8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdXtokenFarmBase(
            xscream,
            scream,
            xscream_poolId,
            "deposit(uint256)",
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[scream] = [oxd, usdc, wftm, scream];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdXscream";
    }
}
