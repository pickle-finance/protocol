// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-nearpad-base.sol";

contract StrategyPadRoseLp is StrategyNearPadFarmBase {
    uint256 public pad_rose_poolid = 17;
    // Token addresses
    address public pad_rose_lp = 0xC6C3cc84EabD4643C382C988fA2830657fc70a6B;
    address public rose = 0xdcD6D4e2B3e1D1E1E6Fa8C21C8A323DcbecfF970;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            pad,
            rose,
            pad_rose_poolid,
            pad_rose_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[rose] = [pad, rose];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPadRoseLp";
    }
}
