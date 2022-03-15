pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/ODDZ Liquidity Pool with PNG and ODDZ rewards
contract StrategyPngAvaxOddz is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 87;
    address public png_avax_oddz_lp = 0xBAe8Ee2D95Aa5c68Fe8373Cd0208227E94075D5d;
    
    address public oddz = 0xB0a6e056B587D0a85640b39b1cB44086F7a26A1E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_oddz_lp,
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
        uint256 _oddz = IERC20(oddz).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_oddz > 0) {
            uint256 _keep = _oddz.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, oddz);
            }  

            _oddz = IERC20(oddz).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for ODDZ
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, oddz, _wavax.div(2)); 
        }      

        /// @dev In the case of ODDZ Rewards, swap half ODDZ for WAVAX
         if(_oddz > 0){
            IERC20(oddz).safeApprove(pangolinRouter, 0);
            IERC20(oddz).safeApprove(pangolinRouter, _oddz.div(2));   
            _swapPangolin(oddz, wavax, _oddz.div(2)); 
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and ODDZ
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > ODDZ
            _swapBaseToToken(_png.div(2), png, oddz);    
        }

        /// @dev Add in liquidity for AVAX/ODDZ
        _wavax = IERC20(wavax).balanceOf(address(this));
        _oddz = IERC20(oddz).balanceOf(address(this));

        if (_wavax > 0 && _oddz > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(oddz).safeApprove(pangolinRouter, 0);
            IERC20(oddz).safeApprove(pangolinRouter, _oddz);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                oddz,
                _wavax,
                _oddz,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _oddz = IERC20(oddz).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_oddz > 0){
                IERC20(oddz).safeTransfer(
                    IController(controller).treasury(),
                    _oddz
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
        return "StrategyPngAvaxOddz";
    }
}