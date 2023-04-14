// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyWbtcEthUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0;
    address private wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
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
        tokenToNativeRoutes[wbtc] = abi.encodePacked(wbtc, uint24(500), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyWbtcEthUniV3";
    }
}
