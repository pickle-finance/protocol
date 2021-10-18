// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyPngFarmBase is StrategyStakingRewardsBase {

    // WAVAX/<token1> pair
    address public token1;

    constructor(
        address _token1,
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;
    }

    // **** State Mutations ****

    function _takeFeePngToSnob(uint256 _keep) internal {
        IERC20(png).safeApprove(pangolinRouter, 0);
        IERC20(png).safeApprove(pangolinRouter, _keep);
        _swapPangolin(png, snob, _keep);
        uint _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects PNG tokens
        IStakingRewards(rewards).getReward();
        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is locked up for future gov
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png.sub(_keep));
            
            if (token1 == png) {
                _swapPangolin(png, wavax, _png.sub(_keep).div(2));
            } else {            
                _swapPangolin(png, wavax, _png.sub(_keep));
            }
             
        }

        // Swap half WAVAX for token
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0 && token1 != png) {
            _swapPangolin(wavax, token1, _wavax.div(2));
        }

        // Adds in liquidity for WAVAX/token
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        _png = IERC20(png).balanceOf(address(this));
        if (_wavax > 0 && _token1 > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(token1).safeApprove(pangolinRouter, 0);
            IERC20(token1).safeApprove(pangolinRouter, _token1);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                token1,
                _wavax,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back PNG LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
