// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxSushiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_sushi_lp_rewards = 0xDA354352b03f87F84315eEF20cdD83c49f7E812e;
    address public png_avax_sushi_lp = 0xd8B262C0676E13100B33590F10564b46eeF652AD;
    address public sushi = 0x39cf1BD5f15fb22eC3D9Ff86b0727aFc203427cc;

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
