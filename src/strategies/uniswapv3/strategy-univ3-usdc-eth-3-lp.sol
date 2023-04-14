// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyUsdcEth3UniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
    address private usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
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
        tokenToNativeRoutes[usdc] = abi.encodePacked(usdc, uint24(3000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcEth3UniV3";
    }
}
