// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxSushiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_sushi_lp_rewards = 0x2D55341f2abbb5472020e2d556a4f6B951C8Fa22;
    address public png_avax_sushi_lp = 0xF62381AFFdfd27Dba91A1Ea2aCf57d426E28c341;
    address public sushi = 0x37B608519F91f70F2EeB0e5Ed9AF4061722e4F76;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            sushi,
            png_avax_sushi_lp_rewards,
            png_avax_sushi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxSushiLp";
    }
}
