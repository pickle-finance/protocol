// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCronaUsdtLp is StrategyCronaFarmBase {
    uint256 public crona_usdt_poolId = 6;

    // Token addresses
    address public crona_usdt_lp = 0x0427F9C304b0028f67A5fD61ffdD613186c1894B;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            crona,
            usdt,
            crona_usdt_poolId,
            crona_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [crona, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCronaUsdtLp";
    }
}
