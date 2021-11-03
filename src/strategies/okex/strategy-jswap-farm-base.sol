// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/jswap-chef.sol";
import "hardhat/console.sol";

abstract contract StrategyJswapFarmBase is StrategyBase {
    // Token addresses
    address public constant jswap = 0x5fAc926Bf1e638944BB16fb5B787B5bA4BC85b0A;
    address public constant jswapChef = 0x83C35EA2C32293aFb24aeB62a14fFE920C2259ab;
    address public constant jswapRouter = 0x069A306A638ac9d3a68a6BD8BE898774C073DCb3;

    // <token0>/<token1> pair
    address public token0;
    address public token1;

    uint256 public poolId;
    mapping(address => address[]) public uniswapRoutes;

    constructor(
        address _token0,
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
        sushiRouter = jswapRouter; //use Jswap router instead of cherry router
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, , ) = IJswapChef(jswapChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return IJswapChef(jswapChef).pendingJf(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(jswapChef, 0);
            IERC20(want).safeApprove(jswapChef, _want);
            IJswapChef(jswapChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IJswapChef(jswapChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects JF tokens
        IJswapChef(jswapChef).deposit(poolId, 0);
        uint256 _jswap = IERC20(jswap).balanceOf(address(this));

        // If JF is in the token pair
        if (_jswap > 0) {
            uint256 toToken0 = _jswap.div(2);
            uint256 toToken1 = _jswap.sub(toToken0);

            if (uniswapRoutes[token0].length > 1) {
                _swapSushiswapWithPath(uniswapRoutes[token0], toToken0);
            }
            if (uniswapRoutes[token1].length > 1) {
                _swapSushiswapWithPath(uniswapRoutes[token1], toToken1);
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

            UniswapRouterV2(sushiRouter).addLiquidity(token0, token1, _token0, _token1, 0, 0, address(this), now + 60);

            // Donates DUST
            IERC20(token0).transfer(IController(controller).treasury(), IERC20(token0).balanceOf(address(this)));
            IERC20(token1).safeTransfer(IController(controller).treasury(), IERC20(token1).balanceOf(address(this)));
        }

        // We want to get back CHE-LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
