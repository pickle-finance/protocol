// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-raider-farm-base.sol";

contract StrategyAurumUsdcLp is StrategyRaiderFarmBase {
    // Token addresses
    address public aurum_usdc_lp = 0xaBEE7668a96C49D27886D1a8914a54a5F9805041;
    address public aurum_usdc_rewards = 0x3bfC2f02D8d7E09902D203Dff3AD6C0e1a614106;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRaiderFarmBase(
            aurum_usdc_lp,
            aurum_usdc_rewards,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyAurumUsdcLp";
    }
}
