// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spiritswap-base.sol";

contract StrategySpiritFtmDeus is StrategySpiritBase {
    address public lp = 0x2599Eba5fD1e49F294C76D034557948034d6C96E;
    address public spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address public deus = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;

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
        swapRoutes[deus] = [wftm, deus];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpiritFtmDeus";
    }
}
