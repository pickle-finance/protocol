// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaUsdtCronaLp is StrategyCronaFarmBase {
    uint256 public usdt_crona_poolId = 14;

    // Token addresses
    address public usdt_crona_lp = 0x0427F9C304b0028f67A5fD61ffdD613186c1894B;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            usdt,
            crona,
            usdt_crona_poolId,
            usdt_crona_lp,
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
        return "StrategyCronaUsdtCronaLp";
    }
}
