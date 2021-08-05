// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngSushiEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_sushi_png_lp_rewards = 0x923E69322Bea5e22799a29Dcfc9c616F3B5cF95b;
    address public png_sushi_png_lp = 0xd71a0530b9396d169CF6E48f9e6d72b9594859Ed;
    address public sushi = 0x37B608519F91f70F2EeB0e5Ed9AF4061722e4F76;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            sushi,
            png_sushi_png_lp_rewards,
            png_sushi_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngSushiEPngLp";
    }
}
