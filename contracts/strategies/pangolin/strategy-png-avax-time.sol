// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxTimeLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_time_lp_rewards =
        0x0875E51e54FBB7e63B1819acb069Dc8d684563EB;
    address public png_avax_time_lp =
        0x2F151656065E1d1bE83BD5b6F5e7509b59e6512D;
    address public time = 0xb54f16fB19478766A268F172C9480f8da1a7c9C3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            time,
            png_avax_time_lp_rewards,
            png_avax_time_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxTimeLp";
    }
}
