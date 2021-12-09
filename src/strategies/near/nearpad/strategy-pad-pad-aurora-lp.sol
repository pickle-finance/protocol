// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadPadAuroraLp is StrategyNearPadFarmBase {
    uint256 public pad_aurora_poolid = 11;
    // Token addresses
    address public pad_aurora_lp = 0xac187A18f9DaB50506fc8111aa7E86F5F55DefE9;
    address public pad = 0xDA2585430fEf327aD8ee44Af8F1f989a2A91A3d2;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            aurora,
            pad_aurora_poolid,
            pad_aurora_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[aurora] = [pad, aurora];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadPadAuroraLp";
    }
}
