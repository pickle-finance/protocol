// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSpookyWethWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 15;
    // Token addresses
    address public _lp = 0xf0702249F4D3A25cD3DED7859a165693685Ab577;
    address public weth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;

    // Spiritswap router
    address public _router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyLqdrFarmLPBase(
            _lp,
            _poolId,
            _router,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[weth] = [wftm, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrSpookyWethWftm";
    }
}
