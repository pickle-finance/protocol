
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cherry-farm-base.sol";

contract StrategyCherryBtckUsdtLp is StrategyCherryFarmBase {
    uint256 public btck_usdt_poolId = 4;

    // Token addresses
    address public cherry_btck_usdt_lp = 0x94E01843825eF85Ee183A711Fa7AE0C5701A731a;
    address public btck = 0x54e4622DC504176b3BB432dCCAf504569699a7fF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCherryFarmBase(
            usdt,
            btck,
            btck_usdt_poolId,
            cherry_btck_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [cherry, usdt];
        uniswapRoutes[btck] = [cherry, usdt, btck];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyCherryBtckUsdtLp";
    }
}
