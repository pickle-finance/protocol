// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyMovrRibLp is StrategySolarFarmBase {
    uint256 public movr_rib_poolId = 4;

    // Token addresses
    address public movr_rib_lp = 0x0acDB54E610dAbC82b8FA454b21AD425ae460DF9;
    address public rib = 0xbD90A6125a84E5C512129D622a75CDDE176aDE5E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            movr,
            rib,
            movr_rib_poolId,
            movr_rib_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[movr] = [solar, movr];
        uniswapRoutes[rib] = [solar, movr, rib];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMovrRibLp";
    }
}
