// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-v2.sol";

contract StrategyPngAvaxGbLp is StrategyPngFarmBaseV2 {
    // Token addresses
    address public png_avax_gb_lp_rewards =
        0x6cFdB5Ce2a26a5b07041618fDAD81273815c8bb4;
    address public png_avax_gb_lp = 0x0A1041fEB651b1daa2f23EBa7DAB3898D6b9A4Fe;
    address public gb = 0x90842eb834cFD2A1DB0b1512B254a18E4D396215;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBaseV2(
            gb,
            png_avax_gb_lp_rewards,
            png_avax_gb_lp,
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
            IERC20(png).safeApprove(pangolinRouter, _png.sub(_keep));

            _swapPangolin(png, wavax, _png.sub(_keep));
        }

        // Swap half WAVAX for GB
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.mul(100).div(199));
            _swapPangolin(wavax, gb, _wavax.mul(100).div(199));
        }

        // Adds in liquidity for AVAX/GB
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _gb = IERC20(gb).balanceOf(address(this));
        if (_wavax > 0 && _gb > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(gb).safeApprove(pangolinRouter, 0);
            IERC20(gb).safeApprove(pangolinRouter, _gb);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                gb,
                _wavax,
                _gb,
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
            _gb = IERC20(gb).balanceOf(address(this));
            if (_gb > 0) {
                IERC20(gb).safeTransfer(
                    IController(controller).treasury(),
                    _gb
                );
            }
        }
        // We want to get back PNG LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxGbLp";
    }
}
