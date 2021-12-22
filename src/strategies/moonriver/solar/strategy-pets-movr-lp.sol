// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyPetsMovrLp is StrategySolarFarmBase {
    uint256 public pets_movr_poolId = 20;

    // Token addresses
    address public pets_movr_lp = 0x9f9a7a3f8F56AFB1a2059daE1E978165816cea44;
    address public pets = 0x1e0F2A75Be02c025Bd84177765F89200c04337Da;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            pets,
            movr,
            pets_movr_poolId,
            pets_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[pets] = [solar, movr, pets];
        uniswapRoutes[movr] = [solar, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPetsMovrLp";
    }
}
