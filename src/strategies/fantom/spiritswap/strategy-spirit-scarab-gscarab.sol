// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spiritswap-base.sol";

contract StrategySpiritScarabGscarab is StrategySpiritBase {
    address public lp = 0x8e38543d4c764DBd8f8b98C73407457a3D3b4999;
    address public spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address public scarab = 0x2e79205648B85485731CFE3025d66cF2d3B059c4;
    address public gscarab = 0x6ab5660f0B1f174CFA84e9977c15645e4848F5D6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySpiritBase(
            lp,
            spiritRouter,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[scarab] = [wftm, scarab];
        swapRoutes[gscarab] = [wftm, gscarab];
        IERC20(wftm).approve(pairRouter, uint256(-1));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpiritScarabGscarab";
    }
}
