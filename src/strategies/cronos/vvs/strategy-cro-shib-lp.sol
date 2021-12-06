// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cronos-farm-base.sol";

contract StrategyCroShibLp is StrategyVVSFarmBase {
    uint256 public cro_shib_poolId = 8;

    // Token addresses
    address public cro_shib_lp = 0xc9eA98736dbC94FAA91AbF9F4aD1eb41e7fb40f4;
    address public shib = 0xbED48612BC69fA1CaB67052b42a95FB30C1bcFee;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            cro,
            shib,
            cro_shib_poolId,
            cro_shib_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[shib] = [vvs, cro, shib];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroShibLp";
    }
}
