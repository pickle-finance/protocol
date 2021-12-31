pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxImxa is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 34;

    // Token addresses
    address public png_avax_imxa_lp = 0xA34862a7de51a0E1aEE6d3912c3767594390586d;
    address public imxa = 0xeA6887e4a9CdA1B77E70129E5Fba830CdB5cdDef;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_imxa_lp,
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

        // Swap half WAVAX for IMXA
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, imxa, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/IMXA
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _imxa = IERC20(imxa).balanceOf(address(this));

        if (_wavax > 0 && _imxa > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(imxa).safeApprove(pangolinRouter, 0);
            IERC20(imxa).safeApprove(pangolinRouter, _imxa);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                imxa,
                _wavax,
                _imxa,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _imxa = IERC20(imxa).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_imxa > 0){
                IERC20(imxa).safeTransfer(
                    IController(controller).treasury(),
                    _imxa
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxImxa";
    }
}