// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance.sol";

contract StrategyGmxEthUniV3Arbi is StrategyRebalanceUniV3 {
    address public constant gmx_eth_pool = 0x1aEEdD3727A6431b8F070C0aFaA81Cc74f273882;
    address public constant gmx = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(gmx_eth_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock)
    {
        tokenToNativeRoutes[gmx] = abi.encodePacked(gmx, uint24(3000), weth);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyGmxEthUniV3Arbi";
    }
}
