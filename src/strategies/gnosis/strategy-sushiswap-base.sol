// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichefv2.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategySushiFarmBase is StrategyBase {
    // Token addresses
    address public constant sushi = 0x2995D1317DcD4f0aB89f4AE60F3f020A4F17C7CE;
    address public extraReward;
    address public constant miniChef = 0xdDCbf776dF3dE60163066A5ddDF2277cB445E0F3;

    // WETH/<token1> pair
    address public token0;
    address public token1;

    uint256 public keepREWARD = 420;
    uint256 public constant keepREWARDMax = 10000;

    uint256 public poolId;
    mapping(address => address[]) public swapRoutes;
    bool extraRewardBool;

    constructor(
        bool _extraRewardBool,
        address _extraReward,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_lp, _governance, _strategist, _controller, _timelock) {
        poolId = _poolId;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();
        extraRewardBool = _extraRewardBool;
        extraReward = _extraReward;

        IERC20(token0).approve(sushiRouter, uint256(-1));
        IERC20(token1).approve(sushiRouter, uint256(-1));
        IERC20(sushi).approve(sushiRouter, uint256(-1));
        IERC20(extraReward).approve(sushiRouter, uint256(-1));
        IERC20(want).approve(miniChef, uint256(-1));
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefV2(miniChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingSushi = IMiniChefV2(miniChef).pendingSushi(poolId, address(this));

        IRewarder rewarder = IMiniChefV2(miniChef).rewarder(poolId);
        (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(poolId, address(this), 0);

        uint256 _pendingExtraReward;
        if (_rewardAmounts.length > 0) {
            _pendingExtraReward = _rewardAmounts[0];
        }

        return (_pendingSushi, _pendingExtraReward);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IMiniChefV2(miniChef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IMiniChefV2(miniChef).withdraw(poolId, _amount, address(this));
        return _amount;
    }

    // **** State Mutations ****

    function setKeepREWARD(uint256 _keepREWARD) external {
        require(msg.sender == timelock, "!timelock");
        keepREWARD = _keepREWARD;
    }

    function harvest() public override onlyBenevolent {
        IMiniChefV2(miniChef).harvest(poolId, address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        // If there is an extraReward
        if (extraRewardBool) {
            uint256 _extraReward = IERC20(extraReward).balanceOf(address(this));
            // If extra reward is part of pair - swap to extraReward to SUSHI,
            // collect fees, and swap half of SUSHI to other token.
            if (extraReward == token0 || extraReward == token1) {
                if (swapRoutes[extraReward].length > 1 && _sushi > 0) {
                    _swap(sushiRouter, swapRoutes[extraReward], _sushi);
                }

                _extraReward = IERC20(extraReward).balanceOf(address(this));
                uint256 _keepReward = _extraReward.mul(keepREWARD).div(keepREWARDMax);
                IERC20(extraReward).safeTransfer(IController(controller).treasury(), _keepReward);

                _extraReward = IERC20(extraReward).balanceOf(address(this));
                address toToken = extraReward == token0 ? token1 : token0;

                if (swapRoutes[toToken].length > 1 && _extraReward > 0) {
                    _swap(sushiRouter, swapRoutes[toToken], _extraReward.div(2));
                }
            }
            // If extraReward not part of pair - swap to SUSHI, collect fees,
            // and swap SUSHI to token0/token1.
            else {
                if (swapRoutes[sushi].length > 1 && _extraReward > 0) {
                    _swap(sushiRouter, swapRoutes[sushi], _extraReward);
                }

                _sushi = IERC20(sushi).balanceOf(address(this));
                uint256 _keepReward = _sushi.mul(keepREWARD).div(keepREWARDMax);
                IERC20(sushi).safeTransfer(IController(controller).treasury(), _keepReward);

                _sushi = _sushi.sub(_keepReward);
                uint256 toToken0 = _sushi.div(2);
                uint256 toToken1 = _sushi.sub(toToken0);

                if (swapRoutes[token0].length > 1) {
                    _swap(sushiRouter, swapRoutes[token0], toToken0);
                }
                if (swapRoutes[token1].length > 1) {
                    _swap(sushiRouter, swapRoutes[token1], toToken1);
                }
            }
            // If there is no extraReward - collect fees and swap SUSHI to token0/token1.
        } else {
            _sushi = IERC20(sushi).balanceOf(address(this));
            uint256 _keepReward = _sushi.mul(keepREWARD).div(keepREWARDMax);
            IERC20(sushi).safeTransfer(IController(controller).treasury(), _keepReward);

            _sushi = _sushi.sub(_keepReward);
            uint256 toToken0 = _sushi.div(2);
            uint256 toToken1 = _sushi.sub(toToken0);

            if (swapRoutes[token0].length > 1) {
                _swap(sushiRouter, swapRoutes[token0], toToken0);
            }
            if (swapRoutes[token1].length > 1) {
                _swap(sushiRouter, swapRoutes[token1], toToken1);
            }
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            UniswapRouterV2(sushiRouter).addLiquidity(token0, token1, _token0, _token1, 0, 0, address(this), now + 60);

            // Donates DUST
            IERC20(token0).transfer(IController(controller).treasury(), IERC20(token0).balanceOf(address(this)));
            IERC20(token1).transfer(IController(controller).treasury(), IERC20(token1).balanceOf(address(this)));
        }

        // We want to get back Sushi LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
