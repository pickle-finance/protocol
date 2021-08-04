// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxDaiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_dai_lp_rewards = 0x701e03fAD691799a8905043C0d18d2213BbCf2c7;
    address public png_avax_dai_lp = 0x17a2E8275792b4616bEFb02EB9AE699aa0DCb94b;
    address public dai = 0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            dai,
            png_avax_dai_lp_rewards,
            png_avax_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxDaiLp";
    }
}
