// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxPefiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_pefi_lp_rewards = 0xd7EDBb1005ec65721a3976Dba996AdC6e02dc9bA;
    address public png_avax_pefi_lp = 0x494Dd9f783dAF777D3fb4303da4de795953592d0;
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
            png_avax_pefi_lp_rewards,
            png_avax_pefi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxPefiLp";
    }
}
