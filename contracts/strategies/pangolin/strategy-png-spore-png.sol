// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-v2.sol";

contract StrategyPngSporePngLp is StrategyPngFarmBaseV2 {
    // Token addresses
    address public png_spore_png_rewards = 0x12A33F6B0dd0D35279D402aB61587fE7eB23f7b0;
    address public png_spore_png_lp = 0xad24a72ffE0466399e6F69b9332022a71408f10b;
    address public spore = 0x6e7f5C0b9f4432716bDd0a77a3601291b9D9e985;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBaseV2(
            spore,
            png_spore_png_rewards,
            png_spore_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

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
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png.sub(_keep).mul(100).div(194));
            
			//swap Pangolin for spore
            _swapPangolin(png, spore, _png.sub(_keep).mul(100).div(194));
                       
        }
           
        // Adds in liquidity for png/spore
        _png = IERC20(png).balanceOf(address(this));
        uint256 _spore = IERC20(spore).balanceOf(address(this));
        if (_png > 0 && _spore > 0) {
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            IERC20(spore).safeApprove(pangolinRouter, 0);
            IERC20(spore).safeApprove(pangolinRouter, _spore);

            IPangolinRouter(pangolinRouter).addLiquidity(
                png,
                spore,
                _png,
                _spore,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _png = IERC20(png).balanceOf(address(this));
            if (_png > 0) {
                IERC20(png).transfer(
                    IController(controller).treasury(),
                    _png
                );
            }
            _spore = IERC20(spore).balanceOf(address(this));
            if (_spore > 0) {
                IERC20(spore).safeTransfer(
                    IController(controller).treasury(),
                    _spore
                );
            }
        }

        // We want to get back PNG LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngSporePngLp";
    }
}	