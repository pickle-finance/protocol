// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../../interfaces/raider-staking.sol";

abstract contract StrategyRaiderFarmBase is StrategyBase {
    // Token addresses
    address public stakingRewards;
    address public constant raider = 0xcd7361ac3307D1C5a46b63086a90742Ff44c63B3;
    address public constant aurum = 0x34d4ab47Bee066F361fA52d792e69AC7bD05ee23;

    // How much RAIDER tokens to keep?
    uint256 public keepRAIDER = 2000;
    uint256 public constant keepRAIDERMax = 10000;

    address public token0;
    address public token1;

    constructor(
        address _lp,
        address _rewards,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        stakingRewards = _rewards;
        token0 = IUniswapV2Pair(_lp).token0();
        token1 = IUniswapV2Pair(_lp).token1();
    }

    function balanceOfPool() public view override returns (uint256) {
        return IRaiderStaking(stakingRewards).addressStakedBalance(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IRaiderStaking(stakingRewards).userPendingRewards(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingRewards, 0);
            IERC20(want).safeApprove(stakingRewards, _want);
            IRaiderStaking(stakingRewards).createStake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IRaiderStaking(stakingRewards).removeStake(_amount);
        return _amount;
    }

    // **** Setters ****

    function setkeepRAIDER(uint256 _keepRAIDER) external {
        require(msg.sender == timelock, "!timelock");
        keepRAIDER = _keepRAIDER;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects RAIDER tokens
        IRaiderStaking(stakingRewards).getRewards();
        uint256 _raider = IERC20(raider).balanceOf(address(this));
        if (_raider > 0) {
            uint256 _keepRAIDER = _raider.mul(keepRAIDER).div(keepRAIDERMax);
            IERC20(raider).safeTransfer(
                IController(controller).treasury(),
                _keepRAIDER
            );
            _raider = IERC20(raider).balanceOf(address(this));

            uint256 toToken0 = _raider.div(2);
            uint256 toToken1 = _raider.sub(toToken0);

            if (token0 != raider) _swapSushiswap(raider, token0, toToken0);
            if (token1 != raider) _swapSushiswap(raider, token1, toToken1);
        }

        // Adds in liquidity 
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

        // We want to get back RAIDER LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
