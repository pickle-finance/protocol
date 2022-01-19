// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaUsdtAvaxLp is StrategyCronaFarmBase {
    uint256 public usdt_avax_poolId = 9;

    // Token addresses
    address public usdt_avax_lp = 0x193add22b0a333956C2Cb13F4D574aF129629c5f;
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
            usdt,
            avax,
            usdt_avax_poolId,
            usdt_avax_lp,
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
        return "StrategyCronaUsdtAvaxLp";
    }
}
