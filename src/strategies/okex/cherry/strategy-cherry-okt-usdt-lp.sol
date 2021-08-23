
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cherry-farm-base.sol";

contract StrategyCherryOktUsdtLp is StrategyCherryFarmBase {
    uint256 public okt_usdt_poolId = 3;

    // Token addresses
    address public cherry_okt_usdt_lp = 0xF3098211d012fF5380A03D80f150Ac6E5753caA8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCherryFarmBase(
            usdt,
            wokt,
            okt_usdt_poolId,
            cherry_okt_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[wokt] = [cherry, usdt, wokt];
        uniswapRoutes[usdt] = [cherry, usdt];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyCherryOktUsdtLp";
    }
}
