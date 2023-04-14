// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyEthLooksUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0x4b5Ab61593A2401B1075b90c04cBCDD3F87CE011;
    address private looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;
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
        tokenToNativeRoutes[looks] = abi.encodePacked(looks, uint24(3000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthLooksUniV3";
    }
}
