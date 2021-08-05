// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxUniLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_uni_lp_rewards = 0x6E36A71c1A211f01Ff848C1319D4e34BB5483224;
    address public png_avax_uni_lp = 0x99dD520748eB0355c69DAE2692E4615C8Ab031ce;
    address public uni = 0x8eBAf22B6F053dFFeaf46f4Dd9eFA95D89ba8580;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            uni,
            png_avax_uni_lp_rewards,
            png_avax_uni_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxUniLp";
    }
}
