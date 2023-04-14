// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance-staker.sol";

contract StrategyUsdcEthUniV3StakerArbi is StrategyRebalanceStakerUniV3 {
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
        StrategyRebalanceStakerUniV3(weth, priv_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        univ3_staker = 0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d;
        rewardToken = 0x0000000000000000000000000000000000000000;

        key = IUniswapV3Staker.IncentiveKey({
            rewardToken: IERC20Minimal(rewardToken),
            pool: IUniswapV3Pool(priv_pool),
            startTime: 0,
            endTime: 1,
            refundee: 0x0000000000000000000000000000000000000000
        });

        tokenToNativeRoutes[usdc] = abi.encodePacked(usdc, uint24(500), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcEthUniV3Arbi";
    }
}
