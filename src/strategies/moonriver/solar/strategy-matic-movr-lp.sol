// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyMaticMovrLp is StrategySolarFarmBase {
    uint256 public matic_movr_poolId = 14;

    // Token addresses
    address public matic_movr_lp = 0x29633cc367AbD9b16d327Adaf6c3538b6e97f6C0;
    address public matic = 0x682F81e57EAa716504090C3ECBa8595fB54561D8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            matic,
            movr,
            matic_movr_poolId,
            matic_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[matic] = [solar, movr, matic];
        uniswapRoutes[movr] = [solar, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMaticMovrLp";
    }
}
