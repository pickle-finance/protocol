// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxMfiLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_mfi_lp_rewards = 0xd64370aeDbEbbAE04CfCaE27E8E0c5ecbD343336;
    address public png_avax_mfi_lp = 0x13bEb85D61035Dc51480AB230CE1cBAa8cC551da;
    address public mfi = 0x9Fda7cEeC4c18008096C2fE2B85F05dc300F94d0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            mfi,
            png_avax_mfi_lp_rewards,
            png_avax_mfi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxMfiLp";
    }
}
