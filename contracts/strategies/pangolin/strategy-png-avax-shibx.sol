// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base-v2.sol";

contract StrategyPngAvaxShibxLp is StrategyPngFarmBaseV2 {
    // Token addresses
    address public png_avax_shibx_lp_rewards =
        0x0029381eFF48E9eA963F8095eA204098ac8e44B5;
    address public png_avax_shibx_lp =
        0x82Ab53e405fa94448597aFCC0BA86143b1AB2628;
    address public shibx = 0x440aBbf18c54b2782A4917b80a1746d3A2c2Cce1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBaseV2(
            shibx,
            png_avax_shibx_lp_rewards,
            png_avax_shibx_lp,
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
            _takeFeePngToSnob(_keep);
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png.sub(_keep));

            _swapPangolin(png, wavax, _png.sub(_keep));
        }

        // Swap half WAVAX for shibx. Reflective 10%
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.mul(100).div(190));
            _swapPangolin(wavax, shibx, _wavax.mul(100).div(190));
        }

        // Adds in liquidity for AVAX/SHIBX
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _shibx = IERC20(shibx).balanceOf(address(this));
        if (_wavax > 0 && _shibx > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(shibx).safeApprove(pangolinRouter, 0);
            IERC20(shibx).safeApprove(pangolinRouter, _shibx);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                shibx,
                _wavax,
                _shibx,
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
            IERC20(shibx).safeTransfer(
                IController(controller).treasury(),
                IERC20(shibx).balanceOf(address(this))
            );
        }

        // We want to get back PNG LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxShibxLp";
    }
}
