// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlBnbNearLp is StrategyBrlFarmBase {
    uint256 public bnb_near_poolid = 9;
    // Token addresses
    address public bnb_near_lp = 0x314ab6AaeE15424ea8De07e2007646EcF3772357;
    address public bnb = 0x2bF9b864cdc97b08B6D79ad4663e71B8aB65c45c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            bnb,
            near,
            bnb_near_poolid,
            bnb_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[bnb] = [brl, near, bnb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlBnbNearLp";
    }
}
