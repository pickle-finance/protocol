// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/swapr-rewarder.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategySwaprFarmBase is StrategyBase {
    // Token addresses
    address public constant swapr = 0x532801ED6f82FFfD2DAB70A19fC2d7B2772C4f4b;
    address public rewarder;
    uint256 public rewardsCount;
    address public constant swaprRouter = 0xE43e60736b1cb4a75ad25240E2f9a62Bff65c0C0;

    // WETH/<token1> pair
    address public token0;
    address public token1;

    uint256 public keepREWARD = 420;
    uint256 public constant keepREWARDMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;
    mapping(address => address[]) public rewardRoutes;

    constructor(
        address _rewarder,
        uint256 _rewardsCount,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        rewarder = _rewarder;
        rewardsCount = _rewardsCount;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();

        IERC20(token0).approve(swaprRouter, uint256(-1));
        IERC20(token1).approve(swaprRouter, uint256(-1));
        IERC20(gno).approve(swaprRouter, uint256(-1));
        IERC20(want).approve(rewarder, uint256(-1));

        // Approve all tokens in the rewards contract.
        address[] memory rewardTokens = ISwaprRewarder(rewarder).getRewardTokens();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardRoutes[rewardTokens[i]].length > 0) {
                IERC20(rewardTokens[i]).approve(swaprRouter, uint256(-1));
            }
        }
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 _amount = ISwaprRewarder(rewarder).stakedTokensOf(address(this));
        return _amount;
    }

    function getHarvestable() external view virtual returns (uint256[] memory) {
        uint256[] memory _claimableRewards = ISwaprRewarder(rewarder).claimableRewards(address(this));
        address[] memory rewardTokens = ISwaprRewarder(rewarder).getRewardTokens();
        uint256[] memory PendingRewards = new uint256[](rewardsCount);

        uint256 j;
        for (uint256 i = 0; i < _claimableRewards.length; i++) {
            if (rewardRoutes[rewardTokens[i]].length > 0) {
                PendingRewards[j] = _claimableRewards[i];
                j++;
            }
        }
        return PendingRewards;
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

    function setKeepREWARD(uint256 _keepREWARD) external {
        require(msg.sender == timelock, "!timelock");
        keepREWARD = _keepREWARD;
    }

    function harvest() public override onlyBenevolent {
        ISwaprRewarder(rewarder).claimAll(address(this));

        // loop through all rewards tokens and swap the ones with
        // rewardRoutes to GNO.
        address[] memory rewardTokens = ISwaprRewarder(rewarder).getRewardTokens();
        for (uint256 i = 0; i > rewardTokens.length; i++) {
            uint256 _rewardToken = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (rewardRoutes[rewardTokens[i]].length > 1) {
                _swap(swaprRouter, rewardRoutes[rewardTokens[i]], _rewardToken);
            }
        }

        // Collect Fees
        uint256 _gno = IERC20(gno).balanceOf(address(this));
        uint256 _keepReward = _gno.mul(keepREWARD).div(keepREWARDMax);
        IERC20(gno).safeTransfer(IController(controller).treasury(), _keepReward);

        _gno = IERC20(gno).balanceOf(address(this));

        if (gno == token0 || gno == token1) {
            if (_gno > 0) {
                address toToken = gno == token0 ? token1 : token0;
                _swap(swaprRouter, swapRoutes[toToken], _gno.div(2));
            }
        } else {
            // Swap GNO to token0 & token1
            if (_gno > 0) {
                uint256 _toToken0 = _gno.div(2);
                uint256 _toToken1 = _gno.sub(_toToken0);

                if (swapRoutes[token0].length > 1) {
                    _swap(swaprRouter, swapRoutes[token0], _toToken0);
                }
                if (swapRoutes[token1].length > 1) {
                    _swap(swaprRouter, swapRoutes[token1], _toToken1);
                }
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(swaprRouter).addLiquidity(token0, token1, _token0, _token1, 0, 0, address(this), now + 60);

            // Donates DUST
            IERC20(token0).transfer(IController(controller).treasury(), IERC20(token0).balanceOf(address(this)));
            IERC20(token1).transfer(IController(controller).treasury(), IERC20(token1).balanceOf(address(this)));
        }

        // We want to get back Swapr LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
