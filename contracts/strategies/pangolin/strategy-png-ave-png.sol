// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngAvePngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_ave_png_lp_rewards = 0x7C960e55C8119457528490C3a34C1438FaF6B039;
    address public png_ave_png_lp = 0x59748d12eC2bf081B306821eE1201A463F94fEa4;
    address public ave = 0x78ea17559B3D2CF85a7F9C2C704eda119Db5E6dE;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            ave,
            png_ave_png_lp_rewards,
            png_ave_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvePngLp";
    }
}
