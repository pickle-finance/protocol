// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/cherry-chef.sol";

abstract contract StrategyCherryFarmBase is StrategyBase {
    // Token addresses
    address public constant cherry = 0x8179D97Eb6488860d816e3EcAFE694a4153F216c;
    address public constant cherryChef =
        0x8cddB4CD757048C4380ae6A69Db8cD5597442f7b;

    // <token0>/<token1> pair
    address public token0;
    address public token1;

    uint256 public poolId;

    constructor(
        address _token0,
        address _token1,
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
        token0 = _token0;
        token1 = _token1;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ICherryChef(cherryChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ICherryChef(cherryChef).pendingCherry(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cherryChef, 0);
            IERC20(want).safeApprove(cherryChef, _want);
            ICherryChef(cherryChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICherryChef(cherryChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects CHERRY tokens
        ICherryChef(cherryChef).deposit(poolId, 0);
        uint256 _cherry = IERC20(cherry).balanceOf(address(this));

        // If CHERRY is in the token pair
        if (_cherry > 0) {
            if (token1 == cherry) {
                _swapSushiswap(cherry, token0, _cherry.div(2));
            } else {

                _swapSushiswap(cherry, usdt, _cherry);

                // Swap half USDT for token0
                uint256 _usdt = IERC20(usdt).balanceOf(address(this));
                if (_usdt > 0 && token0 != usdt) {
                    _swapSushiswap(usdt, token0, _usdt.div(2));
                }

                // Swap half USDT for token1
                if (_usdt > 0 && token1 != usdt) {
                    _swapSushiswap(usdt, token1, _usdt.div(2));
                }
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back CHE-LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
