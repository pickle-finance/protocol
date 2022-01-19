// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyUsdcUsdtLp is StrategyVVSFarmBase {
    uint256 public usdc_usdt_poolId = 6;

    // Token addresses
    address public usdc_usdt_lp = 0x39cC0E14795A8e6e9D02A21091b81FE0d61D82f9;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            usdc,
            usdt,
            usdc_usdt_poolId,
            usdc_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [vvs, usdt];
        uniswapRoutes[usdc] = [vvs, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcUsdtLp";
    }
}
