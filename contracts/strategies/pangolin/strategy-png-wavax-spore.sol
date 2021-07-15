// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;


contract StrategyPngAvaxSporeLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_spore_lp_rewards = 0xd3e5538A049FcFcb8dF559B85B352302fEfB8d7C;
    address public png_avax_spore_lp = 0x0a63179a8838b5729E79D239940d7e29e40A0116;
    address public spore = 0x6e7f5C0b9f4432716bDd0a77a3601291b9D9e985;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            spore,
            png_avax_spore_lp_rewards,
            png_avax_spore_lp,
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
            uint256 _keepPNG = _png.mul(keepPNG).div(keepPNGMax);
            IERC20(png).safeTransfer(
                IController(controller).treasury(),
                _keepPNG
            );
            _swapPangolin(png, wavax, _png.sub(_keepPNG));
        }

        // Swap half WAVAX for SPORE
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, spore, _wavax.mul(25).div(47));
        }

        // Adds in liquidity for AVAX/SPORE
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _spore = IERC20(spore).balanceOf(address(this));
        if (_wavax > 0 && _spore > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(spore).safeApprove(pangolinRouter, 0);
            IERC20(spore).safeApprove(pangolinRouter, _spore);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                spore,
                _wavax,
                _spore,
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
            IERC20(spore).safeTransfer(
                IController(controller).treasury(),
                IERC20(spore).balanceOf(address(this))
            );
        }

        // We want to get back PNG LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxSporeLp";
    }
}