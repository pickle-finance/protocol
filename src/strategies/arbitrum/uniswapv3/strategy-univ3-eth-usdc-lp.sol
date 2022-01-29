// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-univ3-rebalance.sol";

contract StrategyUsdcEthUniV3Arbi is StrategyRebalanceUniV3 {
    address public usdc_eth_pool = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;

    constructor(
        int24 _tickRangeMultiplier,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRebalanceUniV3(usdc_eth_pool, _tickRangeMultiplier, _governance, _strategist, _controller, _timelock){ }

    function getName() external pure override returns (string memory) {
        return "StrategyUsdcEthUniV3Arbi";
    }

}
