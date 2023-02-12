// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyEthUsdcUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x85149247691df622eaF1a8Bd0CaFd40BC45154a9;
    address private weth = 0x4200000000000000000000000000000000000006;
    address private usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

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
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthUsdcUniV3Optimism";
    }
}
