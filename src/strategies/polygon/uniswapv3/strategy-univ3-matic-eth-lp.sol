// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyMaticEthUniV3Poly is StrategyRebalanceUniV3 {
    address private priv_pool = 0x167384319B41F7094e62f7506409Eb38079AbfF8;
    address private constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

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
        tokenToNativeRoutes[weth] = abi.encodePacked(weth, uint24(500), wmatic);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyMaticEthUniV3Poly";
    }
}
