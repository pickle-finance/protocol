// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngDaiPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_dai_png_rewards = 0xe3103e565cF96a5709aE8e603B1EfB7fED04613B;
    address public png_dai_png_lp = 0xD765B31399985f411A9667330764f62153b42C76;
	address public dai = 0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            dai,
            png_dai_png_rewards,
            png_dai_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngDaiPngLp";
    }
}	