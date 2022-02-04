pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxAvxt is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 80;

    // Token addresses
    address public png_avax_avxt_lp = 0x792055e49a6421F7544c5479eCC380bad62Bc7EE;
    address public avxt = 0x397bBd6A0E41bdF4C3F971731E180Db8Ad06eBc1;
    address public enxt = 0x164334Ed9E63FbEdC8B52E6dbD408Af4F051419f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_avxt_lp,
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
        uint256 _enxt = IERC20(enxt).balanceOf(address(this));
        
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

        if (_enxt > 0) {
            uint256 _keep = _enxt.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, enxt);
            }

            _enxt = IERC20(enxt).balanceOf(address(this));  
        }

        // In the case of AVAX Rewards, swap half WAVAX for AVXT
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, avxt, _wavax.div(2)); 
        }      
    
        // In the case of PNG Rewards, swap PNG for WAVAX and AVXT
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapBaseToToken(_png.div(2), png, avxt); 
        }

        // In the case of ENXT Rewards, swap ENXT for WAVAX and AVXT
        if(_enxt > 0){
            IERC20(enxt).safeApprove(pangolinRouter, 0);
            IERC20(enxt).safeApprove(pangolinRouter, _enxt);   
            _swapPangolin(enxt, wavax, _enxt.div(2));
            _swapBaseToToken(_enxt.div(2), enxt, avxt); 
        }

        // Adds in liquidity for AVAX/AVXT
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _avxt = IERC20(avxt).balanceOf(address(this));

        if (_wavax > 0 && _avxt > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(avxt).safeApprove(pangolinRouter, 0);
            IERC20(avxt).safeApprove(pangolinRouter, _avxt);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                avxt,
                _wavax,
                _avxt,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _avxt = IERC20(avxt).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            _enxt = IERC20(enxt).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_avxt > 0){
                IERC20(avxt).safeTransfer(
                    IController(controller).treasury(),
                    _avxt
                );
            }

            if (_png > 0){
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }

            if (_enxt > 0){
                IERC20(enxt).safeTransfer(
                    IController(controller).treasury(),
                    _enxt
                );
            }
        }
    
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxAvxt";
    }
}