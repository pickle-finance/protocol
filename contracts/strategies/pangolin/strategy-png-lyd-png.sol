// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-png.sol";

contract StrategyPngLydPngLp is StrategyPngFarmBasePng {
    // Token addresses
    address public png_lyd_png_lp_rewards = 0xe1314E6d436877850BB955Ac074226FCB0B8a86d;
    address public png_lyd_png_lp = 0x2033C18cA39E53b88762e5Edf5808FC0e3cB2Fb5;
    address public lyd = 0x4C9B4E1AC6F24CdE3660D5E4Ef1eBF77C710C084;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBasePng(
            lyd,
            png_lyd_png_lp_rewards,
            png_lyd_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngLydPngLp";
    }
}
