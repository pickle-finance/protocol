// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../interfaces/lqty-staking.sol";
import "../interfaces/weth.sol";
import "./strategy-base.sol";

abstract contract StrategyTeddyBase is StrategyBase {
    address public rewards;

    // Token addresses
    address public teddy = 0x094bd7B2D99711A1486FB94d4395801C6d0fdDcC;
    address public tsd = 0x4fbf0429599460D327BD5F55625E30E4fC066095;

    constructor(
        address _rewards,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(teddy, _governance, _strategist, _controller, _timelock)
    {
        rewards = _rewards;
    }

    // **** State Mutations ****

    function _takeFeeWavaxToSnob(uint256 _keep) internal {
        IERC20(wavax).safeApprove(pangolinRouter, 0);
        IERC20(wavax).safeApprove(pangolinRouter, _keep);
        _swapPangolin(wavax, snob, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(feeDistributor, _share);
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    function _takeFeeTsdToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = tsd;
        path[1] = wavax;
        path[2] = snob;
        IERC20(tsd).safeApprove(pangolinRouter, 0);
        IERC20(tsd).safeApprove(pangolinRouter, _keep);
        _swapPangolinWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(feeDistributor, _share);
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

        ILiquityStaking(rewards).unstake(0);

        //Swap tsd for teddy
        uint256 _tsd = IERC20(tsd).balanceOf(address(this));

        if (_tsd > 0) {
            // 10% is locked up for future gov
            uint256 _keep = _tsd.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeTsdToSnob(_keep);
            }

            address[] memory path = new address[](3);
            path[0] = tsd;
            path[1] = wavax;
            path[2] = teddy;
            IERC20(tsd).safeApprove(pangolinRouter, 0);
            IERC20(tsd).safeApprove(pangolinRouter, _tsd.sub(_keep));
            _swapPangolinWithPath(path, _tsd.sub(_keep));
        }

        //wrap avax
        uint256 _avax = address(this).balance;
        if (_avax > 0) {
            WETH(wavax).deposit{value: _avax}();
        }

        //Swap wavax for teddy
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        if (_wavax > 0) {
            // 10% is locked up for future gov
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }
            //swap WAVAX for TEDDY
            _swapPangolin(wavax, teddy, _wavax.sub(_keep));
        }

        // Donate Dust of WAVAX
        _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
        }

        // Donate Dust of TSD
        _tsd = IERC20(tsd).balanceOf(address(this));
        if (_tsd > 0) {
            IERC20(tsd).safeApprove(pangolinRouter, 0);
            IERC20(tsd).safeApprove(pangolinRouter, _tsd);

            // Donates DUST
            IERC20(tsd).transfer(
                IController(controller).treasury(),
                IERC20(tsd).balanceOf(address(this))
            );
        }

        // We want to get back UNI LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    function balanceOfPool() public view override returns (uint256) {
        return ILiquityStaking(rewards).stakes(address(this));
    }

    function getHarvestable() public view returns (uint256, uint256) {
        return (
            ILiquityStaking(rewards).getPendingLUSDGain(address(this)),
            ILiquityStaking(rewards).getPendingETHGain(address(this))
        );
    }

    // **** Setters ****
    function deposit() public override {
        uint256 _teddy = IERC20(teddy).balanceOf(address(this));

        if (_teddy > 0) {
            IERC20(teddy).safeApprove(rewards, 0);
            IERC20(teddy).safeApprove(rewards, _teddy);
            ILiquityStaking(rewards).stake(_teddy);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ILiquityStaking(rewards).unstake(_amount);
        return _amount;
    }

    receive() external payable {}
}
