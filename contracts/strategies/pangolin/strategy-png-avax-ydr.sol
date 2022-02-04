pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxYdr is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 82;

    // Token addresses
    address public png_avax_ydr_lp = 0x0EaeeC3Ae72E183Dd701dB6F50077945E0809CDD;
    address public ydr = 0xf03Dccaec9A28200A6708c686cf0b8BF26dDc356;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_ydr_lp,
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
        uint256 _ydr = IERC20(ydr).balanceOf(address(this));
        
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

        if (_ydr > 0) {
            uint256 _keep = _ydr.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ydr);
            }

            _ydr = IERC20(ydr).balanceOf(address(this));  
        }

        // In the case of AVAX Rewards, swap half WAVAX for YDR
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, ydr, _wavax.div(2)); 
        }    

        // In the case of YDR Rewards, swap half YDR for WAVAX
        if(_ydr > 0){
            IERC20(ydr).safeApprove(pangolinRouter, 0);
            IERC20(ydr).safeApprove(pangolinRouter, _ydr);   
            _swapPangolin(ydr, wavax, _ydr.div(2));
        }
  
        // In the case of PNG Rewards, swap PNG for WAVAX and YDR
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapBaseToToken(_png.div(2), png, ydr); 
        }

        // Adds in liquidity for AVAX/YDR
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ydr = IERC20(ydr).balanceOf(address(this));

        if (_wavax > 0 && _ydr > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(ydr).safeApprove(pangolinRouter, 0);
            IERC20(ydr).safeApprove(pangolinRouter, _ydr);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                ydr,
                _wavax,
                _ydr,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ydr = IERC20(ydr).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_ydr > 0){
                IERC20(ydr).safeTransfer(
                    IController(controller).treasury(),
                    _ydr
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
        return "StrategyPngAvaxYdr";
    }
}