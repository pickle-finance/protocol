// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mith-farm-base.sol";

contract StrategyMithMisUsdtLp is StrategyMithFarmBase {
    // Token addresses
    address public mith_rewards = 0x14E33e1D6Cc4D83D7476492C0A52b3d4F869d892;
    address public uni_mis_usdt_lp = 0x066F3A3B7C8Fa077c71B9184d862ed0A4D5cF3e0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMithFarmBase(
            mis,
            mith_rewards,
            uni_mis_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMithMisUsdtLp";
    }
}
