// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/minichefv2.sol";
import "../../interfaces/IRewarder.sol";

abstract contract StrategySushiFarmBase is StrategyBase {
    // Token addresses
    address public constant sushi = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;
    address public constant miniChef =
        0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3;

    // WETH/<token1> pair
    address public token0;
    address public token1;
    address rewardToken;

    // How much SUSHI tokens to keep?
    uint256 public keepSUSHI = 2000;
    uint256 public keepReward = 2000;
    uint256 public constant keepMax = 10000;

    uint256 public poolId;

    constructor(
        address _token0,
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChefV2(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingSushi = IMiniChefV2(miniChef).pendingSushi(
            poolId,
            address(this)
        );
        IRewarder rewarder = IMiniChefV2(miniChef).rewarder(poolId);
        (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(
            poolId,
            address(this),
            0
        );

        uint256 _pendingReward;
        if (_rewardAmounts.length > 0) {
            _pendingReward = _rewardAmounts[0];
        }
        // return IMiniChefV2(miniChef).pendingSushi(poolId, address(this));
        return (_pendingSushi, _pendingReward);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(miniChef, 0);
            IERC20(want).safeApprove(miniChef, _want);
            IMiniChefV2(miniChef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChefV2(miniChef).withdraw(poolId, _amount, address(this));
        return _amount;
    }

    // **** Setters ****

    function setKeepSUSHI(uint256 _keepSUSHI) external {
        require(msg.sender == timelock, "!timelock");
        keepSUSHI = _keepSUSHI;
    }

    function setKeepReward(uint256 _keepReward) external {
        require(msg.sender == timelock, "!timelock");
        keepReward = _keepReward;
    }

    function setRewardToken(address _rewardToken) external {
        require(
            msg.sender == timelock || msg.sender == strategist,
            "!timelock"
        );
        rewardToken = _rewardToken;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects SUSHI tokens
        IMiniChefV2(miniChef).harvest(poolId, address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            // 10% is locked up for future gov
            uint256 _keepSUSHI = _sushi.mul(keepSUSHI).div(keepMax);
            IERC20(sushi).safeTransfer(
                IController(controller).treasury(),
                _keepSUSHI
            );
            _swapSushiswap(sushi, weth, _sushi.sub(_keepSUSHI));
        }

        // Collect reward tokens
        if (rewardToken != address(0)) {
            uint256 _reward = IERC20(rewardToken).balanceOf(address(this));
            if (_reward > 0) {
                uint256 _keepReward = _reward.mul(keepReward).div(keepMax);
                IERC20(rewardToken).safeTransfer(
                    IController(controller).treasury(),
                    _keepReward
                );
                _swapSushiswap(rewardToken, weth, _reward.sub(_keepReward));
            }
        }

        // Swap half WETH for token0
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0 && token0 != weth) {
            _swapSushiswap(weth, token0, _weth.div(2));
        }

        // Swap half WETH for token1
        if (_weth > 0 && token1 != weth) {
            _swapSushiswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back SUSHI LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
