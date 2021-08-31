// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxFraxLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_frax_lp_rewards = 0xfd0824dF1E598D34C3495e1C2a339E2FA23Af40D;
    address public png_avax_frax_lp = 0xf0252ffAF3D3c7b3283E0afF56B66Db7105c318C;
    address public frax = 0xDC42728B0eA910349ed3c6e1c9Dc06b5FB591f98;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            frax,
            png_avax_frax_lp_rewards,
            png_avax_frax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxFraxLp";
    }
}
