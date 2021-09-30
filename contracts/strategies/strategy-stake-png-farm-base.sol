// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyStakePngFarmBase is StrategyStakingRewardsBase {

    // WAVAX/<token1> pair
    address public token1;

    // How much PNG tokens to keep?
    uint256 public keepAVAX = 1000;
    uint256 public constant keepAVAXMax = 10000;

    uint256 public revenueShare = 3000;
    uint256 public constant revenueShareMax = 10000;

    constructor(
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
        token1 = png;
    }

    // **** Setters ****

    function setKeepAVAX (uint256 _keepAVAX ) external {
        require(msg.sender == timelock, "!timelock");
        keepAVAX  = _keepAVAX ;
    }

    function setRevenueShare(uint256 _share) external {
        require(msg.sender == timelock, "!timelock");
        revenueShare = _share;
    }

    // **** State Mutations ****

    function _takeFeeWavaxToSnob(uint256 _keepAVAX) internal {
        IERC20(wavax).safeApprove(pangolinRouter, 0);
        IERC20(wavax).safeApprove(pangolinRouter, _keepAVAX);
        _swapPangolin(wavax, snob, _keepAVAX);
        uint _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share);
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
        
        // Swap WAVAX for token
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            // 10% is locked up for future gov
            uint256 _keepWAVAX = _wavax.mul(keepAVAX).div(keepAVAXMax);
            _takeFeeWavaxToSnob(_keepWAVAX);

            //swap WAVAX for token1
            _swapPangolin(wavax, token1, _wavax.sub(_keepWAVAX).div(2));
        }

        // Donate Dust
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

        // We want to get back PNG LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
