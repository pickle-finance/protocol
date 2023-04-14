// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyUsdcEthUniV3Arbi is StrategyRebalanceUniV3 {
    address private priv_pool = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    address private usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address private weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

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
        return "StrategyUsdcEthUniV3Arbi";
    }
}
