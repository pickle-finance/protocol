// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance-staker.sol";

contract StrategyUsdcUsdtUniV3StakerPoly is StrategyRebalanceStakerUniV3 {
    address private priv_pool = 0x3F5228d0e7D75467366be7De2c31D0d098bA2C23;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceStakerUniV3(
            priv_pool,
            _tickRangeMultiplier,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
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
    }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcUsdtUniV3Poly";
    }
}
