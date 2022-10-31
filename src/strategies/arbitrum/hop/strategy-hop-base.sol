// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "../strategy-base-v2.sol";
import "../../../interfaces/hop/hop-pool.sol";
import "../../../optimism/interfaces/staking-rewards.sol";
import "../../../optimism/interfaces/solidly/IRouter.sol";
import "../../../optimism/interfaces/weth.sol";

abstract contract StrategyHopOptimismBase is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Addresses
    address public constant hop = 0xc5102fE9359FD9a28f877a67E36B0F050d81a3CC;
    address public constant solidRouter = 0xa132DAB612dB5cB9fC9Ac426A0Cc215A3423F9c9;
    address public immutable pool;
    address public immutable staking;
    address public immutable underlying;

    mapping(address => ISolidlyRouter.route[]) public toTokenRoutes;
    mapping(address => ISolidlyRouter.route[]) public toNativeRoutes;

    constructor(
        address _lp,
        address _staking,
        address _underlying,
        address _pool,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        staking = _staking;
        underlying = _underlying;
        pool = _pool;

        // toNativeRoutes
        ISolidlyRouter.route[] memory _hopRoute = new ISolidlyRouter.route[](1);
        _hopRoute[0] = ISolidlyRouter.route(hop, native, false);
        _addToNativeRoute(_hopRoute);

        // Approvals
        IERC20(_underlying).approve(pool, type(uint256).max);
        IERC20(hop).approve(solidRouter, type(uint256).max);
        IERC20(native).approve(solidRouter, type(uint256).max);
        IERC20(want).approve(staking, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(staking).balanceOf(address(this));
    }

    function getHarvestable() external view override returns (address[] memory, uint256[] memory) {
        address[] memory rewardTokens = new address[](1);
        uint256[] memory pendingRewards = new uint256[](1);
        rewardTokens[0] = hop;
        pendingRewards[0] = IStakingRewards(staking).earned(address(this));

        return (rewardTokens, pendingRewards);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IStakingRewards(staking).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IStakingRewards(staking).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****
    // Adds/updates a swap path from a token to native, normally used for adding/updating a reward path
    function addToNativeRoute(ISolidlyRouter.route[] calldata path) external {
        require(msg.sender == timelock, "!timelock");
        _addToNativeRoute(path);
    }

    function _addToNativeRoute(ISolidlyRouter.route[] memory path) internal {
        require(path[path.length - 1].to == native, "!valid route");
        address token = path[0].from;
        if (toNativeRoutes[token].length == 0) {
            activeRewardsTokens.push(token);
        }
        for (uint256 i = 0; i < path.length; i++) {
            toNativeRoutes[token].push(path[i]);
        }
        IERC20(token).approve(solidRouter, type(uint256).max);
    }

    function addToTokenRoute(ISolidlyRouter.route[] calldata path) external {
        require(msg.sender == timelock, "!timelock");

        _addToTokenRoute(path);
    }

    function _addToTokenRoute(ISolidlyRouter.route[] memory path) internal {
        require(path[0].from == native, "!valid route");

        address token = path[path.length - 1].to;
        // Reset old route if necessary
        if (toTokenRoutes[token].length > 0) {
            delete toTokenRoutes[token];
        }

        // Set the route
        for (uint256 i = 0; i < path.length; i++) {
            toTokenRoutes[token].push(path[i]);
        }
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

    function _swapSolidlyWithRoute(ISolidlyRouter.route[] memory routes, uint256 _amount) internal {
        require(routes[0].to != address(0));
        ISolidlyRouter(solidRouter).swapExactTokensForTokens(
            _amount,
            0,
            routes,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _harvestRewards() internal {
        IStakingRewards(staking).getReward();
    }

    function _swapActiveRewardsToNative() internal {
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            uint256 _rewardToken = IERC20(activeRewardsTokens[i]).balanceOf(address(this));
            if (toNativeRoutes[activeRewardsTokens[i]].length > 0 && _rewardToken > 0) {
                _swapSolidlyWithRoute(toNativeRoutes[activeRewardsTokens[i]], _rewardToken);
            }
        }
    }

    function harvest() public override {
        // Collects rewards tokens
        _harvestRewards();

        // loop through all rewards tokens and swap the ones with toNativeRoutes.
        _swapActiveRewardsToNative();

        _distributePerformanceFeesNative();

        // Swap native to deposit token & deposit liquidity
        uint256 _native = IERC20(native).balanceOf(address(this));

        if (_native > 0 && underlying != native) {
            // Swap native to deposit token
            _swapSolidlyWithRoute(toTokenRoutes[underlying], _native);
        }

        uint256 _underlying = IERC20(underlying).balanceOf(address(this));

        if (_underlying > 0) {
            uint256[] memory _amounts = new uint256[](2);
            _amounts[0] = _underlying;
            _amounts[1] = 0;

            // Deposit liquidity
            IHopPool(pool).addLiquidity(_amounts, 0, block.timestamp + 60);
        }

        deposit();
    }

    fallback() external payable {}

    receive() external payable {}
}
