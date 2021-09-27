// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxTeddyLp is StrategyPngFarmBase {
    //Token addresses
    address public png_avax_teddy_lp_rewards =
        0x676247D8729B728BEEa83d1c1314acDD937327b6;
    address public png_avax_teddy_lp =
        0x4F20E367B10674cB45Eb7ede68c33B702E1Be655;
    address public teddy = 0x094bd7B2D99711A1486FB94d4395801C6d0fdDcC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            teddy,
            png_avax_teddy_lp_rewards,
            png_avax_teddy_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxTeddyLp";
    }
}
