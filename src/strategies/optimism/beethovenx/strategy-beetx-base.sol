// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../strategy-base-v2.sol";
import "../../../optimism/interfaces/beethovenx.sol";
import "../../../optimism/interfaces/curve/IRewardsOnlyGauge.sol";
import "../../../optimism/interfaces/curve/IChildChainGaugeRewardHelper.sol";
import "../../../optimism/interfaces/curve/IChildChainStreamer.sol";
import "../../../optimism/lib/balancer-vault.sol";

abstract contract StrategyBeetxBase is StrategyBase {
    struct BalSwapRoute {
        bytes32[] poolIds;
        address[] tokensPath;
    }

    // Token addresses
    address public constant beets = 0x97513e975a7fA9072c72C92d8000B0dB90b163c5;
    address public constant bal = 0xFE8B128bA8C78aabC59d4c64cEE7fF28e9379921;
    address public constant op = 0x4200000000000000000000000000000000000042;
    address public constant vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant rewardHelper = 0x299dcDF14350999496204c141A0c20A29d71AF3E;

    // Pool tokens
    address public depositToken = native;
    address public gauge;
    address[] public poolTokens;
    bytes32 public vaultPoolId;

    mapping(address => BalSwapRoute) private toTokenRoutes;
    mapping(address => BalSwapRoute) private toNativeRoutes;

    constructor(
        bytes32 _vaultPoolId,
        address _gauge,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        vaultPoolId = _vaultPoolId;
        gauge = _gauge;

        (IERC20[] memory _poolTokens, , ) = IBVault(vault).getPoolTokens(vaultPoolId);
        for (uint8 i = 0; i < _poolTokens.length; i++) {
            poolTokens.push(address(_poolTokens[i]));
        }

        // Approvals
        IERC20(want).approve(gauge, type(uint256).max);
        IERC20(native).approve(vault, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        // How much the strategy got staked in the gauge
        uint256 amount = IRewardsOnlyGauge(gauge).balanceOf(address(this));
        return amount;
    }

    function getHarvestable() external view override returns (address[] memory, uint256[] memory) {
        // Doesn't account for strategy's pending rewards on the rewarder
        uint256[] memory pendingRewards = new uint256[](activeRewardsTokens.length);
        address[] memory rewardTokens = new address[](activeRewardsTokens.length);
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            pendingRewards[i] = IRewardsOnlyGauge(gauge).claimable_reward(address(this), activeRewardsTokens[i]);
            rewardTokens[i] = activeRewardsTokens[i];
        }

        return (rewardTokens, pendingRewards);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IRewardsOnlyGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IRewardsOnlyGauge(gauge).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    // Adds/updates a swap path from a token to native, normally used for adding/updating a reward path
    function addToNativeRoute(bytes32[] calldata poolIds, address[] calldata tokensPath) external {
        require(msg.sender == timelock, "!timelock");

        _addToNativeRoute(poolIds, tokensPath);
    }

    // Adds/updates a swap path from native to token
    function addToTokenRoute(bytes32[] calldata poolIds, address[] calldata tokensPath) external {
        require(msg.sender == timelock, "!timelock");

        _addToTokenRoute(poolIds, tokensPath);
    }

    function _addToNativeRoute(bytes32[] memory poolIds, address[] memory tokensPath) internal {
        require(poolIds.length == tokensPath.length - 1 && tokensPath[tokensPath.length - 1] == native, "!valid route");

        // Add new reward token to activeRewardsTokens array and reset old route if necessary
        if (toNativeRoutes[tokensPath[0]].tokensPath.length == 0) {
            activeRewardsTokens.push(tokensPath[0]);
        } else {
            delete toNativeRoutes[tokensPath[0]];
        }

        // Set the route
        toNativeRoutes[tokensPath[0]].tokensPath.push(tokensPath[0]);
        for (uint256 i = 0; i < poolIds.length; i++) {
            toNativeRoutes[tokensPath[0]].tokensPath.push(tokensPath[i + 1]);
            toNativeRoutes[tokensPath[0]].poolIds.push(poolIds[i]);
        }

        // Infinite approve balancer vault
        IERC20(tokensPath[0]).approve(vault, type(uint256).max);
    }

    function _addToTokenRoute(bytes32[] memory poolIds, address[] memory tokensPath) internal {
        require(poolIds.length == tokensPath.length - 1 && tokensPath[0] == native, "!valid route");

        // Reset old route if necessary
        if (toTokenRoutes[tokensPath[tokensPath.length - 1]].poolIds.length > 0) {
            delete toTokenRoutes[tokensPath[tokensPath.length - 1]];
        }

        // Set the route
        toTokenRoutes[tokensPath[tokensPath.length - 1]].tokensPath.push(tokensPath[0]);
        for (uint256 i = 0; i < poolIds.length; i++) {
            toTokenRoutes[tokensPath[tokensPath.length - 1]].tokensPath.push(tokensPath[i + 1]);
            toTokenRoutes[tokensPath[tokensPath.length - 1]].poolIds.push(poolIds[i]);
        }

        // Set the depositToken
        depositToken = tokensPath[tokensPath.length - 1];
        // Infinite approve balancer vault
        IERC20(depositToken).approve(vault, type(uint256).max);
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

    function _swapBalancerWithRoute(BalSwapRoute memory _route, uint256 _amount) internal {
        IAsset[] memory assets = new IAsset[](_route.tokensPath.length);
        assets[0] = IAsset(_route.tokensPath[0]);

        IBVault.BatchSwapStep[] memory steps = new IBVault.BatchSwapStep[](_route.poolIds.length);

        IBVault.FundManagement memory funds = IBVault.FundManagement({
            sender: address(this),
            recipient: payable(address(this)),
            fromInternalBalance: false,
            toInternalBalance: false
        });

        int256[] memory limits = new int256[](_route.tokensPath.length);
        limits[0] = int256(_amount);

        for (uint256 i = 0; i < _route.poolIds.length; i++) {
            assets[i + 1] = IAsset(_route.tokensPath[i + 1]);
            steps[i] = IBVault.BatchSwapStep({
                poolId: _route.poolIds[i],
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: i == 0 ? _amount : 0,
                userData: "0x"
            });

            limits[i + 1] = int256(0);
        }

        IBVault(vault).batchSwap(IBVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, block.timestamp+60);
    }

    function _harvestRewards() internal {
        IChildChainGaugeRewardHelper(rewardHelper).claimRewards(gauge, address(this));
    }

    function _swapActiveRewardsToNative() internal {
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            uint256 _rewardToken = IERC20(activeRewardsTokens[i]).balanceOf(address(this));
            if (toNativeRoutes[activeRewardsTokens[i]].tokensPath.length > 0 && _rewardToken > 0) {
                _swapBalancerWithRoute(toNativeRoutes[activeRewardsTokens[i]], _rewardToken);
            }
        }
    }

    function _joinBalancerPool(uint256 _depositAmount) internal {
        IAsset[] memory assets = new IAsset[](poolTokens.length);
        for (uint8 _i = 0; _i < poolTokens.length; _i++) {
            assets[_i] = IAsset(poolTokens[_i]);
        }

        IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](poolTokens.length);
        for (uint8 _i = 0; _i < poolTokens.length; _i++) {
            if (poolTokens[_i] == depositToken) {
                amountsIn[_i] = _depositAmount;
            } else {
                amountsIn[_i] = 0;
            }
        }

        uint256 minAmountOut = 1;

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBVault.JoinPoolRequest memory request = IBVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: amountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        // Join Balancer pool
        IBVault(vault).joinPool(vaultPoolId, address(this), address(this), request);
    }

    function harvest() public virtual override {
        // Collects rewards tokens
        _harvestRewards();

        // loop through all rewards tokens and swap the ones with toNativeRoutes.
        _swapActiveRewardsToNative();

        // Collect Fees
        _distributePerformanceFeesNative();

        uint256 _native = IERC20(native).balanceOf(address(this));
        if (_native == 0) {
            return;
        }

        // Swap native to to deposit token if necessary
        uint256 _depositAmount = _native;
        if (depositToken != native) {
            _swapBalancerWithRoute(toTokenRoutes[depositToken], _native);
            _depositAmount = IERC20(depositToken).balanceOf(address(this));
        }

        // Mint pool tokens
        _joinBalancerPool(_depositAmount);

        // deposit pool tokens into BeethovenX gauge
        deposit();
    }
}
