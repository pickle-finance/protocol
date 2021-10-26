// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxRocoLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_roco_lp_rewards =
        0x23855F21d158efAE410e3568FB623C35BC1952E0;
    address public png_avax_roco_lp =
        0x4a2cB99e8d91f82Cf10Fb97D43745A1f23e47caA;
    address public roco = 0xb2a85C5ECea99187A977aC34303b80AcbDdFa208;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            roco,
            png_avax_roco_lp_rewards,
            png_avax_roco_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxRocoLp";
    }
}
