// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxPng is StrategyPngMiniChefFarmBase {
    // Token addresses
    uint256 public _poolId = 0;
    address public png_avax_png_lp = 0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367;
    
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_png_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        IMiniChef(miniChef).harvest(poolId, address(this));

        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }
        }

        //Take Avax Rewards    
        uint256 _avax = address(this).balance;           //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
        }
        
        _png = IERC20(png).balanceOf(address(this));
        _wavax = IERC20(wavax).balanceOf(address(this));

        if (_png > 0) {
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png.div(2));

            _swapPangolin(png, wavax, _png.div(2));
        }

        if (_wavax > 0) {
            //convert Avax Rewards
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, png, _wavax.div(2));
        }    

        // Adds in liquidity for AVAX/PNG
        _wavax = IERC20(wavax).balanceOf(address(this));

        _png = IERC20(png).balanceOf(address(this));

        if (_wavax > 0 && _png > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                png,
                _wavax,
                _png,
                0,
                0,
                address(this),
                now + 60
            );


            _wavax = IERC20(wavax).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0) {
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            _png = IERC20(png).balanceOf(address(this));
            if (_png > 0) {
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxPng";
    }
}
