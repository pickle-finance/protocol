// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../strategy-base-v2.sol";

import "../../interfaces/minichefv2.sol";
import "../../interfaces/masterchef-rewarder.sol";
import "../../interfaces/trident-router.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/bentobox.sol";

// Strategy Contract Basics

abstract contract StrategySushiBentoBase is StrategyBase {
    struct RouteStep {
        bool isLegacy;
        address[] legacyPath;
        ITridentRouter.Path[] tridentPath;
    }

    // Tokens
    address public immutable token0;
    address public immutable token1;
    address public immutable sushi;
    address public reward;

    // Protocol info
    address public immutable tridentRouter;
    address public immutable sushiRouter;
    address public immutable bentoBox;
    address public immutable minichef;
    uint256 public immutable poolId;
    address public rewarder;
    bool public isBentoPool;

    mapping(address => RouteStep[]) private nativeToTokenRoutes;
    mapping(address => RouteStep[]) private toNativeRoutes;

    constructor(
        address _want,
        address _sushi,
        address _native,
        address _bento,
        address _tridentRouter,
        address _sushiRouter,
        address _minichef,
        uint256 _poolId,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBase(_want, _native, _governance, _strategist, _controller, _timelock) {
        // Sanity checks
        require(_sushi != address(0));
        require(_bento != address(0));
        require(_minichef != address(0));

        // Constants assignments
        tridentRouter = _tridentRouter;
        sushiRouter = _sushiRouter;
        bentoBox = _bento;
        minichef = _minichef;
        poolId = _poolId;
        token0 = ITridentPair(_want).token0();
        token1 = ITridentPair(_want).token1();
        sushi = _sushi;

        // Approvals
        if (_tridentRouter != address(0)) {
            IBentoBox(_bento).setMasterContractApproval(address(this), _tridentRouter, true, 0, "", "");
        }
        IERC20(_want).approve(_minichef, type(uint256).max);
    }

    // **** Views **** //

    function balanceOfPool() public view override returns (uint256 amount) {
        (amount, ) = IMiniChefV2(minichef).userInfo(poolId, address(this));
    }

    function getHarvestable() external view override returns (address[] memory, uint256[] memory) {
        uint256 length;
        if (rewarder == address(0)) {
            length = 1;
        } else {
            length = 2;
        }

        address[] memory rewardTokens = new address[](length);
        uint256[] memory pendingRewards = new uint256[](length);

        rewardTokens[0] = sushi;
        pendingRewards[0] = IMiniChefV2(minichef).pendingSushi(poolId, address(this));

        if (length > 1) {
            (IERC20[] memory rewarderTokens, uint256[] memory rewarderAmounts) = IMasterchefRewarder(rewarder)
                .pendingTokens(poolId, address(this), 0);
            rewardTokens[1] = address(rewarderTokens[0]);
            pendingRewards[1] = rewarderAmounts[0];
        }

        return (rewardTokens, pendingRewards);
    }

    function getToNativeRouteLength(address _rewardToken) external view returns (uint256) {
        return toNativeRoutes[_rewardToken].length;
    }

    function getToTokenRouteLength(address _token) external view returns (uint256) {
        return nativeToTokenRoutes[_token].length;
    }

    function getToNativeRoute(address _token, uint256 _index)
        external
        view
        returns (
            bool isLegacy,
            address[] memory legacyPath,
            ITridentRouter.Path[] memory tridentPath
        )
    {
        isLegacy = toNativeRoutes[_token][_index].isLegacy;
        legacyPath = toNativeRoutes[_token][_index].legacyPath;
        tridentPath = toNativeRoutes[_token][_index].tridentPath;
    }

    function getToTokenRoute(address _token, uint256 _index)
        external
        view
        returns (
            bool isLegacy,
            address[] memory legacyPath,
            ITridentRouter.Path[] memory tridentPath
        )
    {
        isLegacy = nativeToTokenRoutes[_token][_index].isLegacy;
        legacyPath = nativeToTokenRoutes[_token][_index].legacyPath;
        tridentPath = nativeToTokenRoutes[_token][_index].tridentPath;
    }

    // **** Setters **** //

    function setRewarder(bool _disable) external onlyStrategist {
        _setRewarder(_disable);
    }

    function _setRewarder(bool _disable) internal {
        if (_disable == true) {
            rewarder = address(0);
            reward = address(0);
        } else {
            address _rewarder = address(IMiniChefV2(minichef).rewarder(poolId));
            (IERC20[] memory rewardTokens, ) = IMasterchefRewarder(_rewarder).pendingTokens(poolId, address(this), 0);
            reward = address(rewardTokens[0]);
        }
    }

    // **** State mutations **** //
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IMiniChefV2(minichef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IMiniChefV2(minichef).withdraw(poolId, _amount, address(this));
        return _amount;
    }

    function _addToNativeRoute(bytes memory path) internal override {
        bytes[] memory _routesEncodedArr = abi.decode(path, (bytes[]));
        (bool _isLegacy, bytes memory _tokenPath) = abi.decode(_routesEncodedArr[0], (bool, bytes));

        // Add token to activeRewardsTokens list
        address _token;
        if (_isLegacy == true) {
            address[] memory _path = abi.decode(_tokenPath, (address[]));
            _token = _path[0];
        } else {
            ITridentRouter.Path[] memory _path = abi.decode(_tokenPath, (ITridentRouter.Path[]));
            (_token, , ) = abi.decode(_path[0].data, (address, address, bool));
        }

        if (toNativeRoutes[_token].length == 0) {
            activeRewardsTokens.push(_token);
        } else {
            delete toNativeRoutes[_token];
        }

        for (uint256 i = 0; i < _routesEncodedArr.length; i++) {
            (bool _isLegacy1, bytes memory _pathEncoded) = abi.decode(_routesEncodedArr[0], (bool, bytes));

            // Set allowance for router/bento
            if (_isLegacy1 == true) {
                address[] memory _path = abi.decode(_pathEncoded, (address[]));
                IERC20(_path[0]).approve(sushiRouter, type(uint256).max);

                toNativeRoutes[_token].push();
                toNativeRoutes[_token][i].isLegacy = true;
                toNativeRoutes[_token][i].legacyPath = _path;
            } else {
                ITridentRouter.Path[] memory _path = abi.decode(_pathEncoded, (ITridentRouter.Path[]));
                (address tokenIn, , ) = abi.decode(_path[0].data, (address, address, bool));
                IERC20(tokenIn).approve(bentoBox, type(uint256).max);

                toNativeRoutes[_token].push();
                toNativeRoutes[_token][i].isLegacy = false;
                for (uint256 j = 0; j < _path.length; j++) {
                    toNativeRoutes[_token][i].tridentPath.push(_path[j]);
                }
            }
        }
    }

    function _addToTokenRoute(bytes memory path) internal override {
        (address token, bytes[] memory _encodedRoutes) = abi.decode(path, (address, bytes[]));

        // Delete the old route
        if (nativeToTokenRoutes[token].length > 0) {
            delete nativeToTokenRoutes[token];
        }

        for (uint256 i = 0; i < _encodedRoutes.length; i++) {
            (bool _isLegacy, bytes memory _pathEncoded) = abi.decode(_encodedRoutes[i], (bool, bytes));

            // Set allowance for router/bento
            if (_isLegacy == true) {
                address[] memory _path = abi.decode(_pathEncoded, (address[]));
                IERC20(_path[0]).approve(sushiRouter, type(uint256).max);

                nativeToTokenRoutes[token].push();
                nativeToTokenRoutes[token][i].isLegacy = true;
                nativeToTokenRoutes[token][i].legacyPath = _path;
            } else {
                ITridentRouter.Path[] memory _path = abi.decode(_pathEncoded, (ITridentRouter.Path[]));
                (address tokenIn, , ) = abi.decode(_path[0].data, (address, address, bool));
                IERC20(tokenIn).approve(bentoBox, type(uint256).max);

                nativeToTokenRoutes[token].push();
                nativeToTokenRoutes[token][i].isLegacy = false;
                for (uint256 j = 0; j < _path.length; j++) {
                    nativeToTokenRoutes[token][i].tridentPath.push(_path[j]);
                }
            }
        }
    }

    function _harvestReward() internal {
        IMiniChefV2(minichef).harvest(poolId, address(this));
    }

    function _swapActiveRewardsToNative() internal {
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            uint256 _rewardToken = IERC20(activeRewardsTokens[i]).balanceOf(address(this));
            if (toNativeRoutes[activeRewardsTokens[i]].length > 0 && _rewardToken > 0) {
                _swap(toNativeRoutes[activeRewardsTokens[i]], _rewardToken);
            }
        }
    }

    function _swapNativeToDeposit(uint256 _native) internal {
        if (native == token0 || native == token1) {
            address toToken = native == token0 ? token1 : token0;
            _swap(nativeToTokenRoutes[toToken], _native / 2);
        } else {
            // Swap native to token0 & token1
            uint256 _toToken0 = _native / 2;
            uint256 _toToken1 = _native - _toToken0;
            _swap(nativeToTokenRoutes[token0], _toToken0);
            _swap(nativeToTokenRoutes[token1], _toToken1);
        }
    }

    function _addLiquidity() internal {
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            if (isBentoPool == true) {
                bytes memory data = abi.encode(address(this));
                ITridentRouter.TokenInput[] memory tokenInput = new ITridentRouter.TokenInput[](2);
                tokenInput[0] = ITridentRouter.TokenInput({token: token0, native: true, amount: _token0});
                tokenInput[1] = ITridentRouter.TokenInput({token: token1, native: true, amount: _token1});
                ITridentRouter(tridentRouter).addLiquidity(tokenInput, want, 0, data);
            } else {
                UniswapRouterV2(sushiRouter).addLiquidity(
                    token0,
                    token1,
                    _token0,
                    _token1,
                    0,
                    0,
                    address(this),
                    block.timestamp + 60
                );
            }
        }
    }

    function harvest() public override {
        // Collects rewards tokens
        _harvestReward();

        // loop through all rewards tokens and swap the ones with toNativeRoutes.
        _swapActiveRewardsToNative();

        // Collect Fees
        _distributePerformanceFeesNative();

        uint256 _native = IERC20(native).balanceOf(address(this));
        if (_native == 0) {
            return;
        }

        // Swap native to token0/token1
        _swapNativeToDeposit(_native);

        // Adds in liquidity for token0/token1
        _addLiquidity();

        // Stake
        deposit();
    }

    function _swap(RouteStep[] memory route, uint256 _amount) internal returns (uint256 _outputAmount) {
        _outputAmount = _amount;
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].isLegacy == true) {
                _outputAmount = _swapLegacyWithPath(route[i].legacyPath, _outputAmount);
            } else {
                _outputAmount = _swapTridentWithPath(route[i].tridentPath, _outputAmount);
            }
        }
    }

    function _swapTridentWithPath(ITridentRouter.Path[] memory _path, uint256 _amount)
        internal
        returns (uint256 _outputAmount)
    {
        (address tokenIn, , ) = abi.decode(_path[0].data, (address, address, bool));
        _outputAmount = ITridentRouter(tridentRouter).exactInputWithNativeToken(
            ITridentRouter.ExactInputParams({tokenIn: tokenIn, amountIn: _amount, amountOutMinimum: 0, path: _path})
        );
    }

    function _swapLegacyWithPath(address[] memory path, uint256 _amount) internal returns (uint256 _outputAmount) {
        uint256[] memory _amountsOut = UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
        _outputAmount = _amountsOut[_amountsOut.length - 1];
    }
}
