// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadTriLp is StrategyNearPadFarmBase {
    uint256 public pad_tri_poolid = 12;
    // Token addresses
    address public pad_tri_lp = 0x50F63D48a52397C1a469Ccd057905CC8d2609B85;
    address public tri = 0xFa94348467f64D5A457F75F8bc40495D33c65aBB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            tri,
            pad_tri_poolid,
            pad_tri_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[tri] = [pad, tri];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadTriLp";
    }
}
