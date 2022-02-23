// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-dual-rewards-base.sol";

contract StrategyLqdrDeusWftm is StrategyLqdrDualFarmLPBase {
    uint256 public _poolId = 37;
    // Token addresses
    address public _lp = 0x2599Eba5fD1e49F294C76D034557948034d6C96E;
    address public deus = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;

    // Spiritswap router
    address public router = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyLqdrDualFarmLPBase(
            _lp,
            _poolId,
            router,
            _governance,
            _strategist,
            _controller,
            _timelock,
            deus
        )
    {
        swapRoutes[deus] = [wftm, deus];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrDeusWftm";
    }
}
