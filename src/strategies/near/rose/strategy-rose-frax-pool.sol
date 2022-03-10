// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base-stable.sol";

contract StrategyRoseFraxPool is StrategyRoseFarmStableBase {
    // Token addresses
    address public frax_pool_rewards =
        0xB9D873cDc15e462f5414CCdFe618a679a47831b4;
    address public frax_pool_lp = 0x4463A118A2fB34640ff8eF7Fe1B3abAcd4aC9fB7;
    address public frax_pool = 0xa34315F1ef49392387Dd143f4578083A9Bd33E94;

    // Used for depositing into FRAX pool
    address public three_pool_lp = 0xfF79D5bff48e1C01b722560D6ffDfCe9FC883587;
    address public frax = 0xDA2585430fEf327aD8ee44Af8F1f989a2A91A3d2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmStableBase(
            frax_pool_rewards,
            frax_pool_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(three_pool_lp).approve(frax_pool, uint256(-1));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyRoseFraxPool";
    }

    // **** State Mutations ****
    function harvestFour() public override {
        uint256 _threePool = IERC20(three_pool_lp).balanceOf(address(this));
        if (_threePool > 0) {
            // The FRAX pool accepts [FRAX, 3Pool]
            uint256[2] memory liquidity;
            liquidity[1] = _threePool;
            ICurveFi_2(frax_pool).add_liquidity(liquidity, 0);
        }
    }

    function harvestFive() public {
        // We want to get back Rose LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
