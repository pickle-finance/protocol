// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategySusdDaiUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0xAdb35413eC50E0Afe41039eaC8B930d313E94FA4;
    address private weth = 0x4200000000000000000000000000000000000006;
    address private susd = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;
    address private dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address private usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

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
        tokenToNativeRoutes[susd] = abi.encodePacked(susd, uint24(500), usdc, uint24(500), weth);
        tokenToNativeRoutes[dai] = abi.encodePacked(dai, uint24(3000), weth);
        performanceTreasuryFee = 1000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategySusdDaiUniV3Optimism";
    }
}
