// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/convex-masterchef.sol";

abstract contract StrategyConvexFarmBase is StrategyBase {
    // Token addresses
    address public constant convex = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    address public constant convexMasterchef =
        0x5F465e9fcfFc217c5849906216581a657cd60605;

    uint256 public poolId;

    constructor(
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        poolId = _poolId;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) =
            IConvexMasterchef(convexMasterchef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() public view returns (uint256) {
        return IConvexMasterchef(convexMasterchef).pendingCvx(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(convexMasterchef, 0);
            IERC20(want).safeApprove(convexMasterchef, _want);
            IConvexMasterchef(convexMasterchef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IConvexMasterchef(convexMasterchef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects CVX tokens
        IConvexMasterchef(convexMasterchef).withdraw(poolId, 0);

        uint256 _convex = IERC20(convex).balanceOf(address(this));
        if (_convex > 0) {
            uint256 _amount = _convex.div(2);
            IERC20(convex).safeApprove(sushiRouter, 0);
            IERC20(convex).safeApprove(sushiRouter, _amount);
            _swapSushiswap(convex, weth, _amount);
        }

        // Adds in liquidity for WETH/CVX
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _convex = IERC20(convex).balanceOf(address(this));

        if (_weth > 0 && _convex > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(convex).safeApprove(sushiRouter, 0);
            IERC20(convex).safeApprove(sushiRouter, _convex);

            UniswapRouterV2(sushiRouter).addLiquidity(
                convex,
                weth,
                _convex,
                _weth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(convex).safeTransfer(
                IController(controller).treasury(),
                IERC20(convex).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }
}