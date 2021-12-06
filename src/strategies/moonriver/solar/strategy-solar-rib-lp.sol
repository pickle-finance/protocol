// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategySolarRibLp is StrategySolarFarmBase {
    uint256 public solar_rib_poolId = 3;

    // Token addresses
    address public solar_rib_lp = 0xf9b7495b833804e4d894fC5f7B39c10016e0a911;
    address public rib = 0xbD90A6125a84E5C512129D622a75CDDE176aDE5E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            solar,
            rib,
            solar_rib_poolId,
            solar_rib_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[rib] = [solar, rib];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySolarRibLp";
    }
}
