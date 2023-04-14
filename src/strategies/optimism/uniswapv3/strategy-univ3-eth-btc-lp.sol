// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyEthBtcUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x73B14a78a0D396C521f954532d43fd5fFe385216;
    address private weth = 0x4200000000000000000000000000000000000006;
    address private btc = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;

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
        tokenToNativeRoutes[btc] = abi.encodePacked(btc, uint24(3000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthBtcUniV3Optimism";
    }
}
