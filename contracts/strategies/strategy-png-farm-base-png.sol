// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyPngFarmBasePng is StrategyStakingRewardsBase {

    // WAVAX/<token1> pair
    address public token1;

    // How much PNG tokens to keep?
    uint256 public keepPNG = 0;
    uint256 public constant keepPNGMax = 10000;

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
        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is locked up for future gov
            uint256 _keepPNG = _png.mul(keepPNG).div(keepPNGMax);
            IERC20(png).safeTransfer(
                IController(controller).treasury(),
                _keepPNG
            );
            
            //swap Pangolin for token1
            _swapPangolin(png, token1, _png.sub(_keepPNG).div(2));      
        }
        
        // Adds in liquidity for png/token
        _png = IERC20(png).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_png > 0 && _token1 > 0) {
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            IERC20(token1).safeApprove(pangolinRouter, 0);
            IERC20(token1).safeApprove(pangolinRouter, _token1);

            IPangolinRouter(pangolinRouter).addLiquidity(
                png,
                token1,
                _png,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(png).transfer(
                IController(controller).treasury(),
                IERC20(png).balanceOf(address(this))
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
