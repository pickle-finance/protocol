// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/rally-chef.sol";

abstract contract StrategyRallyFarmBase is StrategyBase {
    // Token addresses
    address public constant rally = 0xf1f955016EcbCd7321c7266BccFB96c68ea5E49b;
    address public constant rallyChef = 0x9CF178df8DDb65B9ea7d4C2f5d1610eB82927230;

    // WETH/<token1> pair
    address public token1;

    uint256 public poolId;

    constructor(
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
        token1 = _token1;
    }

    function balanceOfPool() public override view returns (uint256) {
        (uint256 amount, ) = IRallychef(rallyChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IRallychef(rallyChef).pendingRally(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rallyChef, 0);
            IERC20(want).safeApprove(rallyChef, _want);
            IRallychef(rallyChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IRallychef(rallyChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects RLY tokens
        IRallychef(rallyChef).deposit(poolId, 0);
        uint256 _rally = IERC20(rally).balanceOf(address(this));

        // Swap half to WETH
        if (_rally > 0) {
            IERC20(rally).safeApprove(univ2Router2, 0);
            IERC20(rally).safeApprove(univ2Router2, _rally.div(2));
            _swapUniswap(rally, weth, _rally.div(2));
        }

        if (token1 != rally) {
            uint256 _remainingRally = IERC20(rally).balanceOf(address(this));
            IERC20(rally).safeApprove(univ2Router2, 0);
            IERC20(rally).safeApprove(univ2Router2, _remainingRally);
            _swapUniswap(rally, token1, _remainingRally);
        }

        // Adds in liquidity for ETH/token1
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);
            IERC20(token1).safeApprove(univ2Router2, 0);
            IERC20(token1).safeApprove(univ2Router2, _token1);

            UniswapRouterV2(univ2Router2).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
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
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back RLY LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
