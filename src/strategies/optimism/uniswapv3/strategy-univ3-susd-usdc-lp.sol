// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategySusdUsdcUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x8EdA97883a1Bc02Cf68C6B9fb996e06ED8fDb3e5;
    address private weth = 0x4200000000000000000000000000000000000006;
    address private usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private susd = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;

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
        tokenToNativeRoutes[susd] = abi.encodePacked(susd, uint24(500), usdc, uint24(500), weth);
        performanceTreasuryFee = 1000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategySusdUsdcUniV3Optimism";
    }
}
