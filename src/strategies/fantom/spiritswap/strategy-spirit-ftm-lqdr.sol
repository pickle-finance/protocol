// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spiritswap-base.sol";

contract StrategySpiritFtmLqdr is StrategySpiritBase {
    address public lp = 0x4Fe6f19031239F105F753D1DF8A0d24857D0cAA2;
    address public spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address public lqdr = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;

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
        swapRoutes[lqdr] = [wftm, lqdr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySpiritFtmLqdr";
    }
}
