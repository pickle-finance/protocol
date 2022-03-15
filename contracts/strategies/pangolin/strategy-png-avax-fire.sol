pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/FIRE Liquidity Pool with PNG and FIRE rewards
contract StrategyPngAvaxFire is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 83;
    address public png_avax_fire_lp = 0x45324950c6ba08112EbF72754004a66a0a2b7721;
    
    address public fire = 0xfcc6CE74f4cd7eDEF0C5429bB99d38A3608043a5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_fire_lp,
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
        uint256 _fire = IERC20(fire).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_fire > 0) {
            uint256 _keep = _fire.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, fire);
            }  

            _fire = IERC20(fire).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for FIRE
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, fire, _wavax.div(2)); 
        }      

        /// @dev In the case of FIRE Rewards, swap half FIRE for WAVAX
         if(_fire > 0){
            IERC20(fire).safeApprove(pangolinRouter, 0);
            IERC20(fire).safeApprove(pangolinRouter, _fire.div(2));   
            _swapPangolin(fire, wavax, _fire.div(2)); 
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and FIRE
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > FIRE
            _swapBaseToToken(_png.div(2), png, fire);    
        }

        /// @dev Add in liquidity for AVAX/FIRE
        _wavax = IERC20(wavax).balanceOf(address(this));
        _fire = IERC20(fire).balanceOf(address(this));

        if (_wavax > 0 && _fire > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(fire).safeApprove(pangolinRouter, 0);
            IERC20(fire).safeApprove(pangolinRouter, _fire);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                fire,
                _wavax,
                _fire,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _fire = IERC20(fire).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_fire > 0){
                IERC20(fire).safeTransfer(
                    IController(controller).treasury(),
                    _fire
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
        return "StrategyPngAvaxFire";
    }
}