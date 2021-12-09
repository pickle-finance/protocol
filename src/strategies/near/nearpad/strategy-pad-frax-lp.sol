// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadFraxLp is StrategyNearPadFarmBase {
    uint256 public pad_frax_poolid = 14;
    // Token addresses
    address public pad_frax_lp = 0xB53bC2537e641C37c7B7A8D33aba1B30283CDA2f;
    address public frax = 0xDA2585430fEf327aD8ee44Af8F1f989a2A91A3d2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            frax,
            pad_frax_poolid,
            pad_frax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[frax] = [pad, frax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadFraxLp";
    }
}
