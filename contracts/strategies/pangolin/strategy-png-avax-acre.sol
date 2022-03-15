pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/ACRE Liquidity Pool with PNG and ACRE rewards
contract StrategyPngAvaxAcre is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 89;
    address public png_avax_acre_lp = 0x64694FC8dFCA286bF1A15b0903FAC98217dC3AD7;
    
    address public acre = 0x00EE200Df31b869a321B10400Da10b561F3ee60d;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_acre_lp,
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
        uint256 _acre = IERC20(acre).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_acre > 0) {
            uint256 _keep = _acre.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, acre);
            }  

            _acre = IERC20(acre).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for ACRE
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, acre, _wavax.div(2)); 
        }      

        /// @dev In the case of ACRE Rewards, swap half ACRE for WAVAX
         if(_acre > 0){
            IERC20(acre).safeApprove(pangolinRouter, 0);
            IERC20(acre).safeApprove(pangolinRouter, _acre.div(2));   
            _swapPangolin(acre, wavax, _acre.div(2)); 
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and ACRE
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > ACRE
            _swapBaseToToken(_png.div(2), png, acre);    
        }

        /// @dev Add in liquidity for AVAX/ACRE
        _wavax = IERC20(wavax).balanceOf(address(this));
        _acre = IERC20(acre).balanceOf(address(this));

        if (_wavax > 0 && _acre > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(acre).safeApprove(pangolinRouter, 0);
            IERC20(acre).safeApprove(pangolinRouter, _acre);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                acre,
                _wavax,
                _acre,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _acre = IERC20(acre).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_acre > 0){
                IERC20(acre).safeTransfer(
                    IController(controller).treasury(),
                    _acre
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
        return "StrategyPngAvaxAcre";
    }
}