// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxBifiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_bifi_lp_rewards =
        0x4E258f7ec60234bb6f3Ea7eCFf5931901182Bd6E;
    address public png_avax_bifi_lp =
        0xAaCE68f9C8506610929D76a0729c7C24603641fC;
    address public bifi = 0xd6070ae98b8069de6B494332d1A1a81B6179D960;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            bifi,
            png_avax_bifi_lp_rewards,
            png_avax_bifi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxBifiLp";
    }
}
