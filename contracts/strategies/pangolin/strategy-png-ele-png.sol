// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngElePngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_ele_png_lp_rewards = 0xfcB0C53FC5c71005D11C6838922e254323b7Ca06;
    address public png_ele_png_lp = 0x02C165cd4F3943a226a6ac852a6e92397dAc0356;
    address public ele = 0xAcD7B3D9c10e97d0efA418903C0c7669E702E4C0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            ele,
            png_ele_png_lp_rewards,
            png_ele_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngElePngLp";
    }
}
