// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyUsdcUsdtUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6;
    address private usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(weth, priv_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        tokenToNativeRoutes[usdc] = abi.encodePacked(usdc, uint24(500), weth);
        tokenToNativeRoutes[usdt] = abi.encodePacked(usdt, uint24(100), usdc, uint24(500), weth);
        performanceTreasuryFee = 1000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcUsdtUniV3";
    }
}
