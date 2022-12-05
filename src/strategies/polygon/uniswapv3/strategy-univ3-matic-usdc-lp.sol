// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyMaticUsdcUniV3Poly is StrategyRebalanceUniV3 {
    address private priv_pool = 0x88f3C15523544835fF6c738DDb30995339AD57d6;
    address private constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(
            wmatic,
            priv_pool,
            _tickRangeMultiplier,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        tokenToNativeRoutes[usdc] = abi.encodePacked(usdc, uint24(3000), wmatic);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyMaticUsdcUniV3Poly";
    }
}
