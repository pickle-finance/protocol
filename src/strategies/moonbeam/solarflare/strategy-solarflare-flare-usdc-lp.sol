// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-solarflare-farm-base.sol";

contract StrategyFlareFlareUsdcLp is StrategyFlareFarmBase {
    uint256 public flare_usdc_poolId = 12;

    // Token addresses
    address public flare_usdc_lp = 0x976888647affb4b2d7Ac1952cB12ca048cD67762;
    address public usdc = 0x8f552a71EFE5eeFc207Bf75485b356A0b3f01eC9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFlareFarmBase(
            flare_usdc_lp,
            flare_usdc_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [flare, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFlareFlareUsdcLp";
    }
}
