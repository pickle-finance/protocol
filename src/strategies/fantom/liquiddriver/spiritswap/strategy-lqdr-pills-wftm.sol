// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrPillsWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 35;
    // Token addresses
    address public _lp = 0x9C775D3D66167685B2A3F4567B548567D2875350;
    address public pills = 0xB66b5D38E183De42F21e92aBcAF3c712dd5d6286;

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
        swapRoutes[pills] = [wftm, pills];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrPillsWftm";
    }
}
