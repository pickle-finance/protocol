pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxDypLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 28;

    // Token addresses
    address public png_avax_dyp_lp = 0x497070e8b6C55fD283D8B259a6971261E2021C01;
    address public dyp = 0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_dyp_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Png tokens
        IMiniChef(miniChef).harvest(poolId, address(this));

        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));

            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            _swapPangolin(png, wavax, _png);     
        }

        // Swap half WAVAX for DYP
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, dyp, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/DYP
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _dyp = IERC20(dyp).balanceOf(address(this));

        if (_wavax > 0 && _dyp > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(dyp).safeApprove(pangolinRouter, 0);
            IERC20(dyp).safeApprove(pangolinRouter, _dyp);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                dyp,
                _wavax,
                _dyp,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _dyp = IERC20(dyp).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_dyp > 0){
                IERC20(dyp).safeTransfer(
                    IController(controller).treasury(),
                    _dyp
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxDypLp";
    }
}