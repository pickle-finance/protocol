// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyMovrRelayLp is StrategySolarFarmBase {
    uint256 public movr_relay_poolId = 16;

    // Token addresses
    address public movr_relay_lp = 0x9e0d90ebB44c22303Ee3d331c0e4a19667012433;
    address public relay = 0xAd7F1844696652ddA7959a49063BfFccafafEfe7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            movr,
            relay,
            movr_relay_poolId,
            movr_relay_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[movr] = [solar, movr];
        uniswapRoutes[relay] = [solar, movr, relay];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMovrRelaybLp";
    }
}
