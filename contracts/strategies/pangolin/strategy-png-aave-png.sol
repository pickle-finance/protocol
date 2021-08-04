// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngAavePngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_aave_png_rewards = 0xFd9ACEc0F413cA05d5AD5b962F3B4De40018AD87;
    address public png_aave_png_lp = 0x0025CEBD8289BBE0a51a5c85464Da68cBc2ec0c4;
	address public aave = 0x8cE2Dee54bB9921a2AE0A63dBb2DF8eD88B91dD9;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            aave,
            png_aave_png_rewards,
            png_aave_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAavePngLp";
    }
}	