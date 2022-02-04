pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxIme is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 79;

    // Token addresses
    address public png_avax_ime_lp = 0xB6eE4A02F1fa523559B9Abb54C50dF3011911fe9;
    address public ime = 0xF891214fdcF9cDaa5fdC42369eE4F27F226AdaD6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_ime_lp,
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
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }


        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        // In the case of AVAX Rewards, swap half WAVAX for IME
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, ime, _wavax.div(2)); 
        }      

    
        // In the case of PNG Rewards, swap PNG for WAVAX and IME
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapBaseToToken(_png.div(2), png, ime); 
        }

        // Adds in liquidity for AVAX/IME
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _ime = IERC20(ime).balanceOf(address(this));

        if (_wavax > 0 && _ime > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(ime).safeApprove(pangolinRouter, 0);
            IERC20(ime).safeApprove(pangolinRouter, _ime);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                ime,
                _wavax,
                _ime,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ime = IERC20(ime).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_ime > 0){
                IERC20(ime).safeTransfer(
                    IController(controller).treasury(),
                    _ime
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
        return "StrategyPngAvaxIme";
    }
}