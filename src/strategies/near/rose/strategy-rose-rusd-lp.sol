// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base-stable.sol";

contract StrategyRoseRusdPool is StrategyRoseFarmStableBase {
    // Token addresses
    address public rusd_pool_rewards =
        0x9286d58C1c8d434Be809221923Cf4575f7A4d058;
    address public rusd_pool_lp = 0x56f87a0cB4713eB513BAf57D5E81750433F5fcB9;
    address public rusd_pool = 0x79B0a67a4045A7a8DC04b17456F4fe15339cBA34;

    // Used for depositing into RUSD pool
    address public three_pool_lp = 0xfF79D5bff48e1C01b722560D6ffDfCe9FC883587;
    address public rusd = 0x19cc40283B057D6608C22F1D20F17e16C245642E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmStableBase(
            rusd_pool_rewards,
            rusd_pool_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(three_pool_lp).approve(rusd_pool, uint256(-1));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyRoseRusdPool";
    }

    // **** State Mutations ****
    function harvestFour() public override {
        uint256 _threePool = IERC20(three_pool_lp).balanceOf(address(this));
        if (_threePool > 0) {
            // The RUSD pool accepts [RUSD, 3Pool]
            uint256[2] memory liquidity;
            liquidity[1] = _threePool;
            ICurveFi_2(rusd_pool).add_liquidity(liquidity, 0);
        }
    }

    function harvestFive() public {
        // We want to get back Rose LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
