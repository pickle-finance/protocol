// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxDaiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_aave_lp_rewards = 0x4dF32F1F8469648e89E62789F4246f73fe768b8E;
    address public png_avax_aave_lp = 0x5F233A14e1315955f48C5750083D9A44b0DF8B50;
    address public aave = 0x8cE2Dee54bB9921a2AE0A63dBb2DF8eD88B91dD9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            aave,
            png_avax_aave_lp_rewards,
            png_avax_aave_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxAaveLp";
    }
}
