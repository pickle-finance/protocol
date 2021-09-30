// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxApeinLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_apein_lp_rewards =
        0xac102f66A1670508DFA5753Fcbbba80E0648a0c7;
    address public png_avax_apein_lp =
        0x8dEd946a4B891D81A8C662e07D49E4dAee7Ab7d3;
    address public apein = 0x938FE3788222A74924E062120E7BFac829c719Fb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            apein,
            png_avax_apein_lp_rewards,
            png_avax_apein_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxApeinLp";
    }
}
