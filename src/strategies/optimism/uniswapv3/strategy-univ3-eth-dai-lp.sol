// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyEthDaiUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x03aF20bDAaFfB4cC0A521796a223f7D85e2aAc31;
    address private weth = 0x4200000000000000000000000000000000000006;
    address private dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

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
        tokenToNativeRoutes[dai] = abi.encodePacked(dai, uint24(3000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthDaiUniV3Optimism";
    }
}
