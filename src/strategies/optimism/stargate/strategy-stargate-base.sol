// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "../strategy-base-v2.sol";
import "../../../optimism/interfaces/stargate/ILPStakingTime.sol";
import "../../../optimism/interfaces/stargate/IStargateRouter.sol";
import "../../../optimism/interfaces/solidly/IRouter.sol";
import "../../../optimism/interfaces/weth.sol";


abstract contract StrategyStargateOptimismBase is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Addresses
    address public constant op = 0x4200000000000000000000000000000000000042;
    address public constant stakingContract = 0x4DeA9e918c6289a52cd469cAC652727B7b412Cd2;
    address public constant solidRouter = 0xa132DAB612dB5cB9fC9Ac426A0Cc215A3423F9c9;

    address public immutable starRouter;
    address public immutable underlying;
    uint256 public immutable poolId; // poolId on staking contract
    uint256 public immutable lpPoolId; // poolId on Stargate router

    mapping(address => ISolidlyRouter.route[]) public toTokenRoutes;
    mapping(address => ISolidlyRouter.route[]) public toNativeRoutes;

    constructor(
        address _lp,
        uint256 _lpPoolId,
        uint256 _poolId,
        address _underlying,
        address _starRouter,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        poolId = _poolId;
        lpPoolId = _lpPoolId;
        underlying = _underlying;
        starRouter = _starRouter;

        // toNativeRoutes
        ISolidlyRouter.route[] memory _opRoute = new ISolidlyRouter.route[](1);
        _opRoute[0] = ISolidlyRouter.route(op, native, false);
        _addToNativeRoute(_opRoute);

        // Approvals
        IERC20(_underlying).approve(_starRouter, type(uint256).max);
        IERC20(op).approve(solidRouter, type(uint256).max);
        IERC20(native).approve(solidRouter, type(uint256).max);
        IERC20(want).approve(stakingContract, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ILPStakingTime(stakingContract).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view override returns (address[] memory, uint256[] memory) {
        uint256[] memory pendingRewards = new uint256[](1);
        address[] memory rewardTokens = new address[](1);
        pendingRewards[0] = ILPStakingTime(stakingContract).pendingEmissionToken(poolId, address(this));
        rewardTokens[0] = ILPStakingTime(stakingContract).eToken();

        return (rewardTokens, pendingRewards);
    }

    // **** Setters ****

    function deposit() public override {
        uint128 _want = uint128(IERC20(want).balanceOf(address(this)));
        if (_want > 0) {
            ILPStakingTime(stakingContract).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ILPStakingTime(stakingContract).withdraw(poolId, _amount);
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
        ISolidlyRouter(solidRouter).swapExactTokensForTokens(_amount, 0, routes, address(this), block.timestamp.add(60));
    }

    function _harvestRewards() internal {
        ILPStakingTime(stakingContract).deposit(poolId, 0);
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
        if (_native > 0) {
          if (underlying == native) {
            // Swap weth to eth
            WETH(native).withdraw(_native);
            // Deposit liquidity
            IStargateRouter(starRouter).addLiquidityETH{value: _native}();
          } else {
            // Swap native to deposit token
            _swapSolidlyWithRoute(toTokenRoutes[underlying], _native);
            uint256 _underlying = IERC20(underlying).balanceOf(address(this));
            // Deposit liquidity
            IStargateRouter(starRouter).addLiquidity( lpPoolId, _underlying, address(this));
          }

        }

        deposit();
    }

    fallback() external payable {}

    receive() external payable {}
}
