pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxLinkELp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 10;

    // Token addresses
    address public png_avax_linke_lp = 0x5875c368Cddd5FB9Bf2f410666ca5aad236DAbD4;
    address public linke = 0x5947BB275c521040051D82396192181b413227A3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_linke_lp,
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

        // Swap half WAVAX for LINKe
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, linke, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/LINKe
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _linke = IERC20(linke).balanceOf(address(this));

        if (_wavax > 0 && _linke > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(linke).safeApprove(pangolinRouter, 0);
            IERC20(linke).safeApprove(pangolinRouter, _linke);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                linke,
                _wavax,
                _linke,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _linke = IERC20(linke).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_linke > 0){
                IERC20(linke).safeTransfer(
                    IController(controller).treasury(),
                    _linke
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxLinkELp";
    }
}