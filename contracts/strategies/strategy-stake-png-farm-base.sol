// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyStakePngFarmBase is StrategyStakingRewardsBase {

    // WAVAX/<token1> pair
    address public token1;

    // How much PNG tokens to keep?
    uint256 public keepPNG = 0;
    uint256 public constant keepPNGMax = 10000;

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

    function setKeepPNG(uint256 _keepPNG) external {
        require(msg.sender == timelock, "!timelock");
        keepPNG = _keepPNG;
    }

    // **** State Mutations ****

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
            _swapPangolin(wavax, token1, _wavax);
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
