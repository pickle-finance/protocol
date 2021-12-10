// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaAvaxUsdtLp is StrategyCronaFarmBase {
    uint256 public avax_usdt_poolId = 9;

    // Token addresses
    address public avax_usdt_lp = 0x193add22b0a333956C2Cb13F4D574aF129629c5f;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address public avax = 0x765277EebeCA2e31912C9946eAe1021199B39C61;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            avax,
            usdt,
            avax_usdt_poolId,
            avax_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [crona, usdt];
        uniswapRoutes[avax] = [crona, usdt, avax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaAvaxUsdtLp";
    }
}
