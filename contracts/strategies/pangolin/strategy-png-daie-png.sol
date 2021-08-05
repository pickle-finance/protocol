// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngDaiEPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_dai_png_lp_rewards = 0xF344611DD94099708e508C2Deb16628578940d77;
    address public png_dai_png_lp = 0x603efefc3ed65e3F5b6730c603B0cfB4426E0f4f;
    address public dai = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            dai,
            png_dai_png_lp_rewards,
            png_dai_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngDaiEPngLp";
    }
}
