// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngPefiPngLp is StrategyPngFarmBase {
    // Token addresses
    address public png_pefi_png_lp_rewards = 0x76e404Ab7357fD97d4f1e8Dd52f298A035fd408c;
    address public png_pefi_png_lp = 0x1bb5541EcCdA68A352649954D4C8eCe6aD68338d;
    address public pefi = 0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            pefi,
            png_pefi_png_lp_rewards,
            png_pefi_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngPefiPngLp";
    }
}
