pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/ZEE Liquidity Pool with PNG and ZEE rewards
contract StrategyPngAvaxZee is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 92;
    address public png_avax_zee_lp = 0xcf0Ea867f202Ae4eBD35bF5e6e9E679C18CeF5EC;
    
    address public zee = 0x44754455564474A89358B2C2265883DF993b12F0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_zee_lp,
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
        uint256 _zee = IERC20(zee).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_zee > 0) {
            uint256 _keep = _zee.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, zee);
            }  

            _zee = IERC20(zee).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for ZEE
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, zee, _wavax.div(2)); 
        }      

        /// @dev In the case of ZEE Rewards, swap half ZEE for WAVAX
         if(_zee > 0){
            IERC20(zee).safeApprove(pangolinRouter, 0);
            IERC20(zee).safeApprove(pangolinRouter, _zee.div(2));   
            _swapPangolin(zee, wavax, _zee.div(2)); 
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and ZEE
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > ZEE
            _swapBaseToToken(_png.div(2), png, zee);    
        }

        /// @dev Add in liquidity for AVAX/ZEE
        _wavax = IERC20(wavax).balanceOf(address(this));
        _zee = IERC20(zee).balanceOf(address(this));

        if (_wavax > 0 && _zee > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(zee).safeApprove(pangolinRouter, 0);
            IERC20(zee).safeApprove(pangolinRouter, _zee);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                zee,
                _wavax,
                _zee,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _zee = IERC20(zee).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_zee > 0){
                IERC20(zee).safeTransfer(
                    IController(controller).treasury(),
                    _zee
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
        return "StrategyPngAvaxZee";
    }
}