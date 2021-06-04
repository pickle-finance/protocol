// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../interfaces/masterchefv2.sol";
import "../../interfaces/alcx-rewarder.sol";

abstract contract StrategyAlcxFarmBase is StrategyBase {
    // Token addresses
    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;
    address public constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    address public constant masterChef =
        0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d;

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
            IMasterchefV2(masterChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() public view returns (uint256) {
        return IMasterchefV2(masterChef).pendingSushi(poolId, address(this));
    }

    function getHarvestableAlcx() public view returns (uint256) {
        address rewarder = IMasterchefV2(masterChef).rewarder(poolId);
        return IAlcxRewarder(rewarder).pendingToken(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            IMasterchefV2(masterChef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterchefV2(masterChef).withdraw(poolId, _amount, address(this));
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and ALCX tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _alcx = IERC20(alcx).balanceOf(address(this));
        if (_alcx > 0) {
            uint256 _amount = _alcx.div(2);
            IERC20(alcx).safeApprove(sushiRouter, 0);
            IERC20(alcx).safeApprove(sushiRouter, _amount);
            _swapSushiswap(alcx, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, alcx, _amount);
        }

        // Adds in liquidity for WETH/ALCX
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _alcx = IERC20(alcx).balanceOf(address(this));

        if (_weth > 0 && _alcx > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(alcx).safeApprove(sushiRouter, 0);
            IERC20(alcx).safeApprove(sushiRouter, _alcx);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                alcx,
                _weth,
                _alcx,
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
            IERC20(alcx).safeTransfer(
                IController(controller).treasury(),
                IERC20(alcx).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }
}
