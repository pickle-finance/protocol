// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaUsdcDaiLp is StrategyStellaFarmBase {
    uint256 public usdc_dai_poolId = 3;

    // Token addresses
    address public usdc_dai_lp = 0x5Ced2f8DD70dc25cbA10ad18c7543Ad9ad5AEeDD;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;
    address public dai = 0x765277EebeCA2e31912C9946eAe1021199B39C61;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            usdc_dai_lp,
            usdc_dai_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [stella, usdc];
        swapRoutes[dai] = [stella, usdc, dai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaUsdcDaiLp";
    }
}
