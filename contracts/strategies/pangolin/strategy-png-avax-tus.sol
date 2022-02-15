pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxTus is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 53;

    // Token addresses
    address public png_avax_tus_lp = 0xbCEd3B6D759B9CA8Fc7706E46Aa81627b2e9EAE8;
    address public tus = 0xf693248F96Fe03422FEa95aC0aFbBBc4a8FdD172;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_tus_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Token Fees
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        // 10% is sent to treasury
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _tus = IERC20(tus).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_tus > 0) {
            uint256 _keep = _tus.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, tus);
            }  

            _tus = IERC20(tus).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        // In the case of AVAX Rewards, swap half WAVAX for TUS
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, tus, _wavax.div(2)); 
        }      

        // In the case of TUS Rewards, swap half TUS for WAVAX
         if(_tus > 0){
            IERC20(tus).safeApprove(pangolinRouter, 0);
            IERC20(tus).safeApprove(pangolinRouter, _tus.div(2));   
            _swapPangolin(tus, wavax, _tus.div(2)); 
        }

        // In the case of PNG Rewards, swap PNG for WAVAX and TUS
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapBaseToToken(_png.div(2), png, tus);    // Need take PNG to WAVAX to swap for TUS
        }

        // Adds in liquidity for AVAX/TUS
        _wavax = IERC20(wavax).balanceOf(address(this));
        _tus = IERC20(tus).balanceOf(address(this));

        if (_wavax > 0 && _tus > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(tus).safeApprove(pangolinRouter, 0);
            IERC20(tus).safeApprove(pangolinRouter, _tus);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                tus,
                _wavax,
                _tus,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _tus = IERC20(tus).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_tus > 0){
                IERC20(tus).safeTransfer(
                    IController(controller).treasury(),
                    _tus
                );
            }

            if (_png > 0){
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }
        }
    
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxTus";
    }
}