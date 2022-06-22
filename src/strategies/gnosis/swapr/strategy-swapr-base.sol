// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base-v2.sol";
import "../../../interfaces/swapr-rewarder.sol";
import "../../../interfaces/IRewarder.sol";

abstract contract StrategySwaprFarmBase is StrategyBase {
    // Addresses
    address public rewarder;
    address[] public activeRewardsTokens;
    address private constant _swaprRouter = 0xE43e60736b1cb4a75ad25240E2f9a62Bff65c0C0;

    address public token0;
    address public token1;

    mapping(address => address[]) public nativeToTokenRoutes;
    mapping(address => address[]) public toNativeRoutes;

    constructor(
        address _rewarder,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        rewarder = _rewarder;
        uniV2Router = _swaprRouter;

        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();

        IERC20(token0).approve(uniV2Router, uint256(-1));
        IERC20(token1).approve(uniV2Router, uint256(-1));
        IERC20(native).approve(uniV2Router, uint256(-1));
        IERC20(want).approve(rewarder, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 _amount = ISwaprRewarder(rewarder).stakedTokensOf(address(this));
        return _amount;
    }

    function getHarvestable() external view override returns (address[] memory, uint256[] memory) {
        uint256[] memory pendingRewards = ISwaprRewarder(rewarder).claimableRewards(address(this));
        address[] memory rewardTokens = ISwaprRewarder(rewarder).getRewardTokens();

        return (rewardTokens, pendingRewards);
    }

    function getActiveRewardsTokens() external view returns (address[] memory) {
        return activeRewardsTokens;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            ISwaprRewarder(rewarder).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        ISwaprRewarder(rewarder).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    // Use to set a new rewarder address, withdraws funds from the old rewarder and deposits to the new one
    function setRewarder(address _rewarder) external {
        require(msg.sender == timelock, "!timelock");

        // Swapr rewarder can revert on claimAll call if there are no outstanding rewards, checking the amounts first
        bool shouldClaimFirst = false;
        uint256[] memory harvestableAmounts = ISwaprRewarder(rewarder).claimableRewards(address(this));
        for (uint256 i = 0; i < harvestableAmounts.length; i++) {
            if (harvestableAmounts[i] > 0) {
                shouldClaimFirst = true;
                break;
            }
        }
        if (shouldClaimFirst) {
            ISwaprRewarder(rewarder).claimAll(address(this));
        }

        // Withdraw all funds
        _withdrawSome(balanceOfPool());
        rewarder = _rewarder;
        IERC20(want).approve(rewarder, uint256(-1));
        deposit();
    }

    // Adds/updates a swap path from a token to native, normally used for adding/updating a reward path
    function addToNativeRoute(address[] calldata path) external {
        require(msg.sender == timelock, "!timelock");
        _addToNativeRoute(path);
    }

    function _addToNativeRoute(address[] memory path) internal {
        if (toNativeRoutes[path[0]].length == 0) {
            activeRewardsTokens.push(path[0]);
        }
        toNativeRoutes[path[0]] = path;
        IERC20(path[0]).approve(uniV2Router, uint256(-1));
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

    function harvest() public override {
        ISwaprRewarder(rewarder).claimAll(address(this));

        // loop through all rewards tokens and swap the ones with
        // toNativeRoutes to XDAI.
        for (uint256 i = 0; i < activeRewardsTokens.length; i++) {
            uint256 _rewardToken = IERC20(activeRewardsTokens[i]).balanceOf(address(this));
            if (toNativeRoutes[activeRewardsTokens[i]].length > 1 && _rewardToken > 0) {
                _swapDefaultWithPath(toNativeRoutes[activeRewardsTokens[i]], _rewardToken);
            }
        }

        // Collect Fees
        _distributePerformanceFeesNative();

        // Swap native to token0/token1
        uint256 _native = IERC20(native).balanceOf(address(this));
        if (_native > 0) {
            if (native == token0 || native == token1) {
                address toToken = native == token0 ? token1 : token0;
                _swapDefaultWithPath(nativeToTokenRoutes[toToken], _native.div(2));
            } else {
                // Swap XDAI to token0 & token1
                uint256 _toToken0 = _native.div(2);
                uint256 _toToken1 = _native.sub(_toToken0);

                if (nativeToTokenRoutes[token0].length > 1) {
                    _swapDefaultWithPath(nativeToTokenRoutes[token0], _toToken0);
                }
                if (nativeToTokenRoutes[token1].length > 1) {
                    _swapDefaultWithPath(nativeToTokenRoutes[token1], _toToken1);
                }
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(uniV2Router).addLiquidity(
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

        deposit();
    }
}
