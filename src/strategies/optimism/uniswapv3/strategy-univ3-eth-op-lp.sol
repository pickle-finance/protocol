// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../uniswapv3/strategy-univ3-rebalance.sol";

contract StrategyEthOpUniV3Optimism is StrategyRebalanceUniV3 {
    address private priv_pool = 0x68F5C0A2DE713a54991E01858Fd27a3832401849;
    address private weth = 0x4200000000000000000000000000000000000006;
    address private op = 0x4200000000000000000000000000000000000042;

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
        tokenToNativeRoutes[op] = abi.encodePacked(op, uint24(3000), weth);
        performanceTreasuryFee = 2000;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyEthOpUniV3Optimism";
    }
}
