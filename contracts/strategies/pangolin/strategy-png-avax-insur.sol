// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxInsurLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_insur_lp_rewards =
        0x41d731926E5B8d3ba70Bb62B9f067A163bE706ab;
    address public png_avax_insur_lp =
        0xEd764838FA66993892fa37D57d4036032B534f24;
    address public insur = 0x544c42fBB96B39B21DF61cf322b5EDC285EE7429;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            insur,
            png_avax_insur_lp_rewards,
            png_avax_insur_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxInsurLp";
    }
}
