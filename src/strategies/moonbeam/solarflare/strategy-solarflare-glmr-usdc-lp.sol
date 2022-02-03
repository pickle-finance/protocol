// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-solarflare-farm-base.sol";

contract StrategyFlareGlmrUsdcLp is StrategyFlareFarmBase {
    uint256 public glmr_usdc_poolId = 1;

    // Token addresses
    address public glmr_usdc_lp = 0xAb89eD43D10c7CE0f4D6F21616556AeCb71b9c5f;
    address public usdc = 0x8f552a71EFE5eeFc207Bf75485b356A0b3f01eC9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFlareFarmBase(
            glmr_usdc_lp,
            glmr_usdc_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [flare, usdc];
        swapRoutes[glmr] = [flare, glmr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFlareGlmrUsdcLp";
    }
}
