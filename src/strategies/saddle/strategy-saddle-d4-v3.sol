// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../strategy-base-v2.sol";

import {ICurveGauge, ICurveMintr} from "../../interfaces/curve.sol";
import {IFraxswapRouterMultihop} from "../../interfaces/fraxswap-router.sol";
import {UniswapRouterV2} from "../../interfaces/uniswapv2.sol";

interface SwapFlashLoan {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external;
}

contract StrategySaddleD4 is StrategyBase {
    using SafeMath for uint256;

    // Tokens
    address private frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address private reward = 0xf1Dc500FdE233A4055e25e5BbF516372BC4F6871; // sdl token
    address private constant _native = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Protocol info
    address public constant gauge = 0x702c1b8Ec3A77009D5898e18DA8F8959B6dF2093;
    address public constant minter = 0x358fE82370a1B9aDaE2E3ad69D6cF9e503c96018;
    address private constant saddle_d4lp = 0xd48cF4D7FB0824CC8bAe055dF3092584d0a1726A;
    address private flashLoan = 0xC69DDcd4DFeF25D8a793241834d4cc4b3668EAD6;

    address private constant fraxswapRouterMultihop = 0x25e9acA5951262241290841b6f863d59D37DC4f0;
    address private constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    mapping(address => IFraxswapRouterMultihop.FraxswapParams) private nativeToTokenRoutes;
    mapping(address => address[]) private toNativeRoutes;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBase(saddle_d4lp, _native, _governance, _strategist, _controller, _timelock) {
        // Performance fees
        performanceTreasuryFee = 2000;

        // Approvals
        IERC20(native).approve(fraxswapRouterMultihop, type(uint256).max);
        IERC20(frax).approve(flashLoan, type(uint256).max);
        IERC20(want).approve(gauge, type(uint256).max);

        // Native to Frax
        IFraxswapRouterMultihop.FraxswapStepData memory _step = IFraxswapRouterMultihop.FraxswapStepData({
            swapType: 0,
            directFundNextPool: 0,
            directFundThisPool: 0,
            tokenOut: frax,
            pool: 0x31351Bf3fba544863FBff44DDC27bA880916A199,
            extraParam1: 1,
            extraParam2: 0,
            percentOfHop: 10000
        });

        bytes[] memory _steps = new bytes[](1);
        _steps[0] = abi.encode(_step);

        IFraxswapRouterMultihop.FraxswapRoute memory _nextRoute = IFraxswapRouterMultihop.FraxswapRoute({
            tokenOut: frax,
            amountOut: 0,
            percentOfHop: 10000,
            steps: _steps,
            nextHops: new bytes[](0)
        });

        bytes[] memory _nextHops = new bytes[](1);
        _nextHops[0] = abi.encode(_nextRoute);

        IFraxswapRouterMultihop.FraxswapRoute memory _route = IFraxswapRouterMultihop.FraxswapRoute({
            tokenOut: address(0),
            amountOut: 0,
            percentOfHop: 10000,
            steps: new bytes[](0),
            nextHops: _nextHops
        });

        IFraxswapRouterMultihop.FraxswapParams memory _params = IFraxswapRouterMultihop.FraxswapParams({
            tokenIn: native,
            amountIn: 0,
            tokenOut: frax,
            amountOutMinimum: 0,
            recipient: address(this),
            deadline: block.timestamp,
            approveMax: false,
            v: 0,
            r: "0x",
            s: "0x",
            route: abi.encode(_route)
        });
        _addToTokenRoute(abi.encode(frax, _params));

        // Reward to native
        address[] memory _rewardToNative = new address[](2);
        _rewardToNative[0] = reward;
        _rewardToNative[1] = native;
        _addToNativeRoute(abi.encode(_rewardToNative));
    }

    function getName() external pure override returns (string memory) {
        return "StrategySaddleD4v2";
    }

    function balanceOfPool() public view override returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    /// @notice callStatic on this
    function getHarvestableStatic() external override returns (address[] memory, uint256[] memory) {
        address[] memory rewardTokens = new address[](1);
        uint256[] memory pendingRewards = new uint256[](1);

        rewardTokens[0] = reward;
        pendingRewards[0] = ICurveGauge(gauge).claimable_tokens(address(this));

        return (rewardTokens, pendingRewards);
    }

    function getToNativeRoute(address _token) external view returns (bytes memory route) {
        route = abi.encode(toNativeRoutes[_token]);
    }

    function getToTokenRoute(address _token) external view returns (bytes memory route) {
        route = abi.encode(nativeToTokenRoutes[_token]);
    }

    // **** Setters ****

    // **** State mutations **** //

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }

    function harvest() public override {
        // Collects rewards tokens
        _harvestReward();

        // loop through all rewards tokens and swap the ones with toNativeRoutes.
        _swapActiveRewardsToNative();

        // Collect Fees
        _distributePerformanceFeesNative();

        uint256 _nativeBalance = IERC20(native).balanceOf(address(this));
        if (_nativeBalance == 0) {
            return;
        }

        // Swap native to frax
        _swapNativeToDeposit(_nativeBalance);

        // Adds in liquidity
        _addLiquidity();

        // Stake
        deposit();
    }

    function _harvestReward() internal {
        ICurveGauge(gauge).claim_rewards(address(this));
        ICurveMintr(minter).mint(address(gauge));
    }

    function _swapActiveRewardsToNative() internal {
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            uint256 _rewardToken = IERC20(activeRewardsTokens[i]).balanceOf(address(this));
            if (toNativeRoutes[activeRewardsTokens[i]].length > 0 && _rewardToken > 0) {
                _swapSushiswapWithPath(toNativeRoutes[activeRewardsTokens[i]], _rewardToken);
            }
        }
    }

    function _swapNativeToDeposit(uint256 _amountIn) internal {
        IFraxswapRouterMultihop.FraxswapParams memory _params = nativeToTokenRoutes[frax];
        _params.amountIn = _amountIn;
        _params.deadline = block.timestamp.add(60);

        IFraxswapRouterMultihop(fraxswapRouterMultihop).swap(_params);
    }

    function _addLiquidity() internal {
        uint256[] memory amounts = new uint256[](4);
        amounts[2] = IERC20(frax).balanceOf(address(this));
        SwapFlashLoan(flashLoan).addLiquidity(amounts, 0, block.timestamp);
    }

    function _swapSushiswapWithPath(address[] memory path, uint256 _amount) internal {
        require(path[1] != address(0));

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp.add(60));
    }

    /// @notice this works exclusively with Fraxswap multihop router v2
    function _addToTokenRoute(bytes memory _route) internal override {
        (address _token, IFraxswapRouterMultihop.FraxswapParams memory _params) = abi.decode(
            _route,
            (address, IFraxswapRouterMultihop.FraxswapParams)
        );

        // Delete the old route
        delete nativeToTokenRoutes[_token];

        nativeToTokenRoutes[_token] = _params;
    }

    /// @notice this works exclusively with Sushiswap legacy router
    function _addToNativeRoute(bytes memory _route) internal override {
        address[] memory _path = abi.decode(_route, (address[]));

        address _token = _path[0];

        if (toNativeRoutes[_token].length == 0) {
            activeRewardsTokens.push(_token);
        } else {
            delete toNativeRoutes[_token];
        }

        IERC20(_token).approve(sushiRouter, type(uint256).max);
        toNativeRoutes[_token] = _path;
    }

    function getHarvestable() external view override returns (address[] memory, uint256[] memory) {
        address[] memory rewardTokens = new address[](1);
        uint256[] memory pendingRewards = new uint256[](1);

        rewardTokens[0] = reward;
        pendingRewards[0] = 0;

        return (rewardTokens, pendingRewards);
    }
}
