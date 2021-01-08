// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-mith-farm-base.sol";

contract StrategyMithMicUsdtLp is StrategyMithFarmBase {
    // Token addresses
    address public mith_rewards = 0x9D9418803F042CCd7647209b0fFd617981D5c619;
    address public uni_mic_usdt_lp = 0xC9cB53B48A2f3A9e75982685644c1870F1405CCb;
    address public mic = 0x368B3a58B5f49392e5C9E4C998cb0bB966752E51;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMithFarmBase(
            mic,
            mith_rewards,
            uni_mic_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMithMicUsdtLp";
    }
}
