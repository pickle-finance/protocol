// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-base-v2.sol";
import "../../../interfaces/solidly.sol";
import "../../../interfaces/curve.sol";

abstract contract StrategyVeloBase is StrategyBase {
    // Addresses
    address public constant solidRouter = 0xa132DAB612dB5cB9fC9Ac426A0Cc215A3423F9c9;
    address public constant velo = 0x3c8B650257cFb5f272f799F5e2b4e65093a11a05;

    address public token0;
    address public token1;

    address public gauge;

    bool public isStablePool;

    mapping(address => RouteParams[]) public nativeToTokenRoutes;
    mapping(address => RouteParams[]) public toNativeRoutes;

    constructor(
        address _lp,
        address _gauge,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        RouteParams[] memory _veloRoute = new RouteParams[](2);
        _veloRoute[0] = RouteParams(velo, 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, false);
        _veloRoute[1] = RouteParams(0x7F5c764cBc14f9669B88837ca1490cCa17c31607, weth, false);
        _addToNativeRoute(_veloRoute);

        gauge = _gauge;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();

        IERC20(native).approve(solidRouter, uint256(-1));
        IERC20(token0).approve(solidRouter, uint256(-1));
        IERC20(token1).approve(solidRouter, uint256(-1));
        IERC20(velo).approve(solidRouter, uint256(-1));
        IERC20(want).approve(gauge, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        return ISolidlyGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external view override returns (address[] memory, uint256[] memory) {
        uint256[] memory pendingRewards = new uint256[](1);
        address[] memory rewardTokens = new address[](1);
        pendingRewards[0] = ISolidlyGauge(gauge).earned(velo, address(this));
        rewardTokens[0] = velo;

        return (rewardTokens, pendingRewards);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            ISolidlyGauge(gauge).deposit(_want, 0);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        ISolidlyGauge(gauge).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    // Adds/updates a swap path from a token to native, normally used for adding/updating a reward path
    function addToNativeRoute(RouteParams[] calldata path) external {
        require(msg.sender == timelock, "!timelock");
        _addToNativeRoute(path);
    }

    function _addToNativeRoute(RouteParams[] memory path) internal {
        if (toNativeRoutes[path[0].from].length == 0) {
            activeRewardsTokens.push(path[0].from);
        }
        for (uint256 i = 0; i < path.length; i++) {
            toNativeRoutes[path[0].from].push(path[i]);
        }
        IERC20(path[0].from).approve(solidRouter, uint256(-1));
    }

    function deactivateReward(address reward) external {
        require(msg.sender == timelock, "!timelock");
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            if (activeRewardsTokens[i] == reward) {
                activeRewardsTokens[i] = activeRewardsTokens[activeRewardsTokens.length - 1];
                activeRewardsTokens.pop();
            }
        }
    }

    function _swapSolidlyWithRoute(RouteParams[] memory routes, uint256 _amount) internal {
        require(routes[0].to != address(0));
        ISolidlyRouter(solidRouter).swapExactTokensForTokens(_amount, 0, routes, address(this), now.add(60));
    }

    function harvest() public override {
        // Collects rewards tokens
        address[] memory _rewardsAddresses = new address[](1);
        _rewardsAddresses[0] = velo;
        ISolidlyGauge(gauge).getReward(address(this), activeRewardsTokens);

        // loop through all rewards tokens and swap the ones with
        // toNativeRoutes.
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            uint256 _rewardToken = IERC20(activeRewardsTokens[i]).balanceOf(address(this));
            if (toNativeRoutes[activeRewardsTokens[i]].length > 0 && _rewardToken > 0) {
                _swapSolidlyWithRoute(toNativeRoutes[activeRewardsTokens[i]], _rewardToken);
            }
        }

        // Collect Fees
        _distributePerformanceFeesNative();

        // Swap native to token0/token1
        uint256 _native = IERC20(native).balanceOf(address(this));

        if (_native > 0) {
            if (native == token0 || native == token1) {
                address toToken = native == token0 ? token1 : token0;
                _swapSolidlyWithRoute(nativeToTokenRoutes[toToken], _native.div(2));
            } else {
                // Swap native to token0 & token1
                uint256 _toToken0 = _native.div(2);
                uint256 _toToken1 = _native.sub(_toToken0);

                if (nativeToTokenRoutes[token0].length > 0) {
                    _swapSolidlyWithRoute(nativeToTokenRoutes[token0], _toToken0);
                }
                if (nativeToTokenRoutes[token1].length > 0) {
                    _swapSolidlyWithRoute(nativeToTokenRoutes[token1], _toToken1);
                }
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            ISolidlyRouter(solidRouter).addLiquidity(
                token0,
                token1,
                isStablePool,
                _token0,
                _token1,
                0,
                0,
                address(this),
                block.timestamp + 60
            );
        }

        deposit();
    }
}
