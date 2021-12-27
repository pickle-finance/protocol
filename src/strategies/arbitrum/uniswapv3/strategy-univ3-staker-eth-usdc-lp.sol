// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance-staker.sol";

contract StrategyUsdcEthUniV3StakerArbi is StrategyRebalanceStakerUniV3 {
    address public usdc_eth_pool = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceStakerUniV3(usdc_eth_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        univ3_staker = 0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d;
        rewardToken = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;

        key = IUniswapV3Staker.IncentiveKey({
            rewardToken: IERC20Minimal(rewardToken),
            pool: IUniswapV3Pool(usdc_eth_pool),
            startTime: 1633694400,
            endTime: 1638878400,
            refundee: 0xDAEada3d210D2f45874724BeEa03C7d4BBD41674
        });

        rewardToken = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcEthUniV3Arbi";
    }
}
