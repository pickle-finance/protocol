// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spiritswap-base.sol";

contract StrategySpiritFtmBifi is StrategySpiritBase {
    address public lp = 0xc28cf9aeBfe1A07A27B3A4d722C841310e504Fe3;
    address public spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address public bifi = 0xd6070ae98b8069de6B494332d1A1a81B6179D960;

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
        swapRoutes[bifi] = [wftm, bifi];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpiritFtmBifi";
    }
}
