// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlBrlNearLp is StrategyBrlFarmBase {
    uint256 public brl_near_poolid = 13;
    // Token addresses
    address public brl_near_lp = 0x5BdAC608cd38C5C8738f5bE20813194A3150d4Ff;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            brl,
            near,
            brl_near_poolid,
            brl_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlBrlNearLp";
    }
}
