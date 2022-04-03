// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSpiritMimWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 7;
    // Token addresses
    address public _lp = 0xB32b31DfAfbD53E310390F641C7119b5B9Ea0488;
    address public mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;

    // Spiritswap router
    address public router = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

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
            router,
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
        return "StrategyLqdrSpiritMimWftm";
    }
}
