// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spiritswap-base.sol";

contract StrategySpiritFtmMai is StrategySpiritBase {
    address public lp = 0x51Eb93ECfEFFbB2f6fE6106c4491B5a0B944E8bd;
    address public spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address public mai = 0xfB98B335551a418cD0737375a2ea0ded62Ea213b;

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
        swapRoutes[mai] = [wftm, mai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpiritFtmMai";
    }
}
