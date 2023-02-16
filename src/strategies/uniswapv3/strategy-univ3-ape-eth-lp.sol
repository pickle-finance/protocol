// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "./strategy-univ3-rebalance.sol";

contract StrategyApeEthUniV3 is StrategyRebalanceUniV3 {
    address private priv_pool = 0xAc4b3DacB91461209Ae9d41EC517c2B9Cb1B7DAF;
    address private ape = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
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
        tokenToNativeRoutes[ape] = abi.encodePacked(ape, uint24(3000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyApeEthUniV3";
    }
}
