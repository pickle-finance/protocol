// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSpookyMimWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 17;
    // Token addresses
    address public _lp = 0x6f86e65b255c9111109d2D2325ca2dFc82456efc;
    address public mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;

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
        swapRoutes[mim] = [wftm, mim];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrSpookyMimWftm";
    }
}
