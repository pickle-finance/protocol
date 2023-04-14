// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyGmxEthUniV3Arbi is StrategyRebalanceUniV3 {
    address private priv_pool = 0x1aEEdD3727A6431b8F070C0aFaA81Cc74f273882;
    address private gmx = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
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
        tokenToNativeRoutes[gmx] = abi.encodePacked(gmx, uint24(3000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyGmxEthUniV3Arbi";
    }
}
