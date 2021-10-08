// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngVsoPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_vso_png_rewards =
        0x759ee0072901f409e4959E00b00a16FD729397eC;
    address public png_vso_png_lp = 0x9D472e21f6589380B21C42674B3585C47b74c891;
    address public vso = 0x846D50248BAf8b7ceAA9d9B53BFd12d7D7FBB25a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            vso,
            png_vso_png_rewards,
            png_vso_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngVsoPngLp";
    }
}
