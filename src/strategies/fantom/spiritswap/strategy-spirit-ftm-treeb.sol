// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spiritswap-base.sol";

contract StrategySpiritFtmTreeb is StrategySpiritBase {
    address public lp = 0x2cEfF1982591c8B0a73b36D2A6C2A6964Da0E869;
    address public spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address public treeb = 0xc60D7067dfBc6f2caf30523a064f416A5Af52963;

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
        swapRoutes[treeb] = [wftm, treeb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpiritFtmTreeb";
    }
}
