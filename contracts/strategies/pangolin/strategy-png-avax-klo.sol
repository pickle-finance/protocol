pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxKlo is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 12;

    // Token addresses
    address public png_avax_klo_lp = 0x6745d7F9289d7d75B5121876B1b9D8DA775c9a3E;
    address public klo = 0xb27c8941a7Df8958A1778c0259f76D1F8B711C35;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_klo_lp,
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

        // Swap half WAVAX for KLO
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, klo, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/KLO
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _klo = IERC20(klo).balanceOf(address(this));

        if (_wavax > 0 && _klo > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(klo).safeApprove(pangolinRouter, 0);
            IERC20(klo).safeApprove(pangolinRouter, _klo);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                klo,
                _wavax,
                _klo,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _klo = IERC20(klo).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_klo > 0){
                IERC20(klo).safeTransfer(
                    IController(controller).treasury(),
                    _klo
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxKlo";
    }
}