// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyEthCowUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0xFCfDFC98062d13a11cec48c44E4613eB26a34293;
    address private cow = 0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB;
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
        tokenToNativeRoutes[cow] = abi.encodePacked(cow, uint24(10000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthCowUniV3";
    }
}
