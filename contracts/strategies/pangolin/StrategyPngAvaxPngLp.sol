  
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxPngLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_png_rewards = 0x8FD2755c6ae7252753361991bDcd6fF55bDc01CE;
    address public png_avax_png_lp = 0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367;
   
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            png,
            png_avax_png_rewards,
            png_avax_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxPngLp";
    }
}
