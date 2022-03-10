// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rose-farm-base-stable.sol";

contract StrategyRoseUstPool is StrategyRoseFarmStableBase {
    // Token addresses
    address public ust_pool_rewards =
        0x56DE5E2c25828040330CEF45258F3FFBc090777C;
    address public ust_pool_lp = 0x94A7644E4D9CA0e685226254f88eAdc957D3c263;
    address public ust_pool = 0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8;
    address public luna = 0xC4bdd27c33ec7daa6fcfd8532ddB524Bf4038096;

    // Used for depositing into UST pool
    address public three_pool_lp = 0xfF79D5bff48e1C01b722560D6ffDfCe9FC883587;

    address public wannaRouter = 0xa3a1eF5Ae6561572023363862e238aFA84C72ef5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRoseFarmStableBase(
            ust_pool_rewards,
            ust_pool_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(three_pool_lp).approve(ust_pool, uint256(-1));
        IERC20(luna).approve(wannaRouter, uint256(-1));
        IERC20(near).approve(sushiRouter, uint256(-1));
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyRoseUstPool";
    }

    // **** State Mutations ****
    function harvestOne() public override {
        // Collect ROSE tokens
        IRoseRewards(rewards).getReward();

        uint256 _luna = IERC20(luna).balanceOf(address(this));
        if (_luna > 0) {
            address[] memory path = new address[](2);
            path[0] = luna;
            path[1] = near;
            _swap(wannaRouter, path, _luna);
        }

        uint256 _near = IERC20(near).balanceOf(address(this));
        if (_near > 0) {
            address[] memory path = new address[](2);
            path[0] = near;
            path[1] = rose;
            _swap(sushiRouter, path, _near);
        }
    }

    function harvestTwo() public override {
        uint256 _rose = IERC20(rose).balanceOf(address(this));

        if (_rose > 0) {
            uint256 _keepROSE = _rose.mul(keepROSE).div(keepROSEMax);
            IERC20(rose).safeTransfer(
                IController(controller).treasury(),
                _keepROSE
            );
        }

        _rose = IERC20(rose).balanceOf(address(this));

        if (_rose > 0) {
            // Use Dai because most premium token in pool
            address[] memory route = new address[](3);
            route[0] = rose;
            route[1] = near;
            route[2] = usdc;
            _swap(sushiRouter, route, _rose);
        }
    }

    function harvestFour() public override {
        uint256 _threePool = IERC20(three_pool_lp).balanceOf(address(this));
        if (_threePool > 0) {
            // The UST pool accepts [UST, 3Pool]
            uint256[2] memory liquidity;
            liquidity[1] = _threePool;
            ICurveFi_2(ust_pool).add_liquidity(liquidity, 0);
        }
    }

    function harvestFive() public {
        // We want to get back Rose LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
