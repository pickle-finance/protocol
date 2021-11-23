// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyAvaxMovrLp is StrategySolarFarmBase {
    uint256 public avax_movr_poolId = 15;

    // Token addresses
    address public avax_movr_lp = 0xb9a61ac826196AbC69A3C66ad77c563D6C5bdD7b;
    address public avax = 0x14a0243C333A5b238143068dC3A7323Ba4C30ECB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            avax,
            movr,
            avax_movr_poolId,
            avax_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[avax] = [solar, movr, avax];
        uniswapRoutes[movr] = [solar, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyAvaxMovrLp";
    }
}
