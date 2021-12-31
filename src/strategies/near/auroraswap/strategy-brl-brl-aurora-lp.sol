// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlBrlAuroraLp is StrategyBrlFarmBase {
    uint256 public brl_aurora_poolid = 15;
    // Token addresses
    address public brl_aurora_lp = 0xDB0363ee28a5B40BDc2f4701e399c63E00f91Aa8;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            brl,
            aurora,
            brl_aurora_poolid,
            brl_aurora_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[aurora] = [brl, aurora];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlBrlAuroraLp";
    }
}
