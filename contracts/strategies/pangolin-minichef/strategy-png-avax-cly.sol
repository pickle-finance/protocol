pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxClyLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 49;

    // Token addresses
    address public png_avax_cly_lp = 0x997B92C4c9d3023C11A937eC322063D952337236;
    address public cly = 0xec3492a2508DDf4FDc0cD76F31f340b30d1793e6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_cly_lp,
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

        // Swap half WAVAX for CLY
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, cly, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/CLY
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _cly = IERC20(cly).balanceOf(address(this));

        if (_wavax > 0 && _cly > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(cly).safeApprove(pangolinRouter, 0);
            IERC20(cly).safeApprove(pangolinRouter, _cly);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                cly,
                _wavax,
                _cly,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _cly = IERC20(cly).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_cly > 0){
                IERC20(cly).safeTransfer(
                    IController(controller).treasury(),
                    _cly
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxClyLp";
    }
}