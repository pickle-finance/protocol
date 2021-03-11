// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxEthLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_eth_lp_rewards = 0xa16381eae6285123c323A665D4D99a6bCfaAC307;
    address public png_avax_eth_lp = 0x1aCf1583bEBdCA21C8025E172D8E8f2817343d65;
    address public eth = 0xf20d962a6c8f70c731bd838a3a388D7d48fA6e15;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            eth,
            png_avax_eth_lp_rewards,
            png_avax_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxEthLp";
    }
}
