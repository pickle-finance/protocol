pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxAmpl is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 21;

    // Token addresses
    address public png_avax_ampl_lp = 0xe36AE366692AcBf696715b6bDDCe0938398Dd991;
    address public ampl = 0x027dbcA046ca156De9622cD1e2D907d375e53aa7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_ampl_lp,
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

        // Swap half WAVAX for AMPL
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, ampl, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/AMPL
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _ampl = IERC20(ampl).balanceOf(address(this));

        if (_wavax > 0 && _ampl > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(ampl).safeApprove(pangolinRouter, 0);
            IERC20(ampl).safeApprove(pangolinRouter, _ampl);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                ampl,
                _wavax,
                _ampl,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _ampl = IERC20(ampl).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_ampl > 0){
                IERC20(ampl).safeTransfer(
                    IController(controller).treasury(),
                    _ampl
                );
            }
        }
        
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxAmpl";
    }
}