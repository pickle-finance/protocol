// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyGlintUsdcUsdtLp is StrategyGlintFarmBase {
    uint256 public usdc_usdt_poolId = 7;

    // Token addresses
    address public usdc_usdt_lp = 0xA35B2c07Cb123EA5E1B9c7530d0812e7e03eC3c1;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;
    address public usdt = 0xeFAeeE334F0Fd1712f9a8cc375f427D9Cdd40d73;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyGlintFarmBase(
            usdc_usdt_lp,
            usdc_usdt_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [glint, glmr, usdc, usdt];
        swapRoutes[usdc] = [glint, glmr, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyGlintUsdcUsdtLp";
    }
}
