pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/sAVAX Liquidity Pool with PNG and QI rewards
contract StrategyPngAvaxSavax is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 90;
    address public png_avax_savax_lp = 0x4E9A38F05c38106C1cf5c145Df24959ec50ff70D;
    
    address public savax = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    address public qi = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_savax_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice **** State Mutations ****
    /// @dev Collect token fees and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMiniChef(miniChef).harvest(poolId, address(this));

        /// @dev Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)  
        uint256 _avax = address(this).balance;              
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }

        /// @dev Check token balances, take fee for each token, then update balances
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _savax = IERC20(savax).balanceOf(address(this));
        uint256 _qi = IERC20(qi).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_savax > 0) {
            uint256 _keep = _savax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, savax);
            }  

            _savax = IERC20(savax).balanceOf(address(this));
        }

        if (_qi > 0) {
            uint256 _keep = _qi.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, qi);
            }  

            _qi = IERC20(qi).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for sAVAX
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, savax, _wavax.div(2)); 
        }      

        /// @dev In the case of sAVAX Rewards, swap half sAVAX for WAVAX
         if(_savax > 0){
            IERC20(savax).safeApprove(pangolinRouter, 0);
            IERC20(savax).safeApprove(pangolinRouter, _savax.div(2));   
            _swapPangolin(savax, wavax, _savax.div(2)); 
        }

        /// @dev In the case of QI Rewards, swap QI for WAVAX and sAVAX
        if(_qi > 0){
            IERC20(qi).safeApprove(pangolinRouter, 0);
            IERC20(qi).safeApprove(pangolinRouter, _qi);   
            _swapPangolin(qi, wavax, _qi.div(2));
            /// @dev Force path QI > WAVAX > sAVAX
            _swapBaseToToken(_qi.div(2), qi, savax);
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and sAVAX
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > sAVAX
            _swapBaseToToken(_png.div(2), png, savax);    
        }

        /// @dev Add in liquidity for AVAX/sAVAX
        _wavax = IERC20(wavax).balanceOf(address(this));
        _savax = IERC20(savax).balanceOf(address(this));

        if (_wavax > 0 && _savax > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(savax).safeApprove(pangolinRouter, 0);
            IERC20(savax).safeApprove(pangolinRouter, _savax);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                savax,
                _wavax,
                _savax,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _savax = IERC20(savax).balanceOf(address(this));
            _qi = IERC20(qi).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_savax > 0){
                IERC20(savax).safeTransfer(
                    IController(controller).treasury(),
                    _savax
                );
            }

            if (_qi > 0){
                IERC20(qi).safeTransfer(
                    IController(controller).treasury(),
                    _qi
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

    /// @notice **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxSavax";
    }
}