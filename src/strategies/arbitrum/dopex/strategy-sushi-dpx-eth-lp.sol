// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-dopex-farm-base.sol";

contract StrategySushiDpxEthLp is StrategyDopexFarmBase {
    // Token addresses
    address public dpx_eth_lp = 0x0C1Cf6883efA1B496B01f654E247B9b419873054;
    address public reward_contract = 0x0000000000000000000000000000000000000000; // TODO

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyDopexFarmBase(
            dpx, // base token
            reward_contract,
            dpx_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDpxEthLp";
    }
}
