// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxYtsLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_yts_lp_rewards = 0x6F571bA11447136fC11BA9AC98f0f0233dAc1BFF;
    address public png_avax_yts_lp = 0x363D093d419093998C06a4f422D73A43156d7f3e;
    address public yts = 0x488F73cddDA1DE3664775fFd91623637383D6404;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            yts,
            png_avax_yts_lp_rewards,
            png_avax_yts_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxYtsLp";
    }
}
