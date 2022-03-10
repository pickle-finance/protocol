// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base-stable.sol";

contract StrategyRoseMaiPool is StrategyRoseFarmStableBase {
    // Token addresses
    address public mai_pool_rewards =
        0x226991aADeEfDe03bF557eF067da95fc613aBfFc;
    address public mai_pool_lp = 0xA7ae42224Bf48eCeFc5f838C230EE339E5fd8e62;
    address public mai_pool = 0x65a761136815B45A9d78d9781d22d47247B49D23;

    // Used for depositing into MAI pool
    address public three_pool_lp = 0xfF79D5bff48e1C01b722560D6ffDfCe9FC883587;
    address public mai = 0xdFA46478F9e5EA86d57387849598dbFB2e964b02;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmStableBase(
            mai_pool_rewards,
            mai_pool_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(three_pool_lp).approve(mai_pool, uint256(-1));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyRoseMaiPool";
    }

    // **** State Mutations ****
    function harvestFour() public override {
        uint256 _threePool = IERC20(three_pool_lp).balanceOf(address(this));
        if (_threePool > 0) {
            // The MAI pool accepts [MAI, 3Pool]
            uint256[2] memory liquidity;
            liquidity[1] = _threePool;
            ICurveFi_2(mai_pool).add_liquidity(liquidity, 0);
        }
    }

    function harvestFive() public {
        // We want to get back Rose LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
