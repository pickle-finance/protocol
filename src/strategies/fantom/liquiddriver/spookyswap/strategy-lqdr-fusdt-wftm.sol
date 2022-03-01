// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrFusdtWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 16;
    // Token addresses
    address public _lp = 0x5965E53aa80a0bcF1CD6dbDd72e6A9b2AA047410;
    address public fusdt = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;

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
        swapRoutes[fusdt] = [wftm, fusdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrFusdtWftm";
    }
}
