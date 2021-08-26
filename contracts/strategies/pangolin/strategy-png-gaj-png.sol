// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngGajPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_gaj_png_lp_rewards = 0x95bD8FDb58692d343C89bC7bc435773779CC0e47;
    address public png_gaj_png_lp = 0xA2cb068e205A8b99Dac4A7C252A4ECffe836b547;
    address public gaj = 0x595c8481c48894771CE8FaDE54ac6Bf59093F9E8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            gaj,
            png_gaj_png_lp_rewards,
            png_gaj_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngGajPngLp";
    }
}
