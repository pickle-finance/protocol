// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrFraxWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 33;
    // Token addresses
    address public _lp = 0x7ed0cdDB9BB6c6dfEa6fB63E117c8305479B8D7D;
    address public frax = 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355;

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
        swapRoutes[frax] = [wftm, frax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrFraxWftm";
    }
}
