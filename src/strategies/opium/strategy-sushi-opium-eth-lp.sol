// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-opium-farm-base.sol";

contract StrategySushiOpiumEthLp is StrategyOpiumFarmBase {
    // Token addresses
    address public opium_rewards = 0x55AB30D01ea1D6626c9B1d65Bee89B563C24A73F;
    address public sushi_opium_eth_lp = 0xD84d55532B231DBB305908bc5A10B8c55ba21e5E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOpiumFarmBase(
            opium,
            opium_rewards,
            sushi_opium_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiOpiumEthLp";
    }
}
