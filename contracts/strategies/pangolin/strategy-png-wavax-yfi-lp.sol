// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxYfiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_yfi_lp_rewards = 0x4dF32F1F8469648e89E62789F4246f73fe768b8E;
    address public png_avax_yfi_lp = 0x7A886B5b2F24eD0Ec0B3C4a17b930E16d160BD17;
    address public yfi = 0x99519AcB025a0e0d44c3875A4BbF03af65933627;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            yfi,
            png_yfi_aave_lp_rewards,
            png_yfi_aave_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxYfiLp";
    }
}
