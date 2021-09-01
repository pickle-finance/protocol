// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxSwapLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_swap_lp_rewards = 0x255e7a0eB5aa1616781702203B042821C35394eF;
    address public png_avax_swap_lp = 0x5BE4063911D88fd07122671C9F3c94693846787c;
    address public swap = 0xc7B5D72C836e718cDA8888eaf03707fAef675079;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            swap,
            png_avax_swap_lp_rewards,
            png_avax_swap_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxSwapLp";
    }
}
