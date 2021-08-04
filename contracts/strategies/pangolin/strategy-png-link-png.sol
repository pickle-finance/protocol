// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngLinkPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_link_png_rewards = 0x6356b24b36074AbE2903f44fE4019bc5864FDe36;
    address public png_link_png_lp = 0x7313835802C6e8CA2A6327E6478747B71440F7a4;
	address public link = 0xB3fe5374F67D7a22886A0eE082b2E2f9d2651651;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            link,
            png_link_png_rewards,
            png_link_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngLinkPngLp";
    }
}	