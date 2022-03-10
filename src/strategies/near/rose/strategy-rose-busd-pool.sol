// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base-stable.sol";

contract StrategyRoseBusdPool is StrategyRoseFarmStableBase {
    // Token addresses
    address public busd_pool_rewards =
        0x18A6115150A060F22Bacf62628169ee9b231368f;
    address public busd_pool_lp = 0x158f57CF9A4DBFCD1Bc521161d86AeCcFC5aF3Bc;
    address public busd_pool = 0xD6cb7Bb7D63f636d1cA72A1D3ed6f7F67678068a;

    // Used for depositing into BUSD pool
    address public three_pool_lp = 0xfF79D5bff48e1C01b722560D6ffDfCe9FC883587;
    address public busd = 0x5C92A4A7f59A9484AFD79DbE251AD2380E589783;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmStableBase(
            busd_pool_rewards,
            busd_pool_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(three_pool_lp).approve(busd_pool, uint256(-1));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyRoseBusdPool";
    }

    // **** State Mutations ****
    function harvestFour() public override {
        uint256 _threePool = IERC20(three_pool_lp).balanceOf(address(this));
        if (_threePool > 0) {
            // The BUSD pool accepts [BUSD, 3Pool]
            uint256[2] memory liquidity;
            liquidity[1] = _threePool;
            ICurveFi_2(busd_pool).add_liquidity(liquidity, 0);
        }
    }

    function harvestFive() public {
        // We want to get back Rose LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
