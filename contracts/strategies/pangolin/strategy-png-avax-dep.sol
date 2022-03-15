pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/DEP Liquidity Pool with PNG and DEP rewards
contract StrategyPngAvaxDep is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 91;
    address public png_avax_dep_lp = 0xE2780d57fEBb8f2C015D2532E1E80FD3dd32Eb17;
    
    address public dep = 0xD4d026322C88C2d49942A75DfF920FCfbC5614C1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_dep_lp,
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
        uint256 _dep = IERC20(dep).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_dep > 0) {
            uint256 _keep = _dep.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, dep);
            }  

            _dep = IERC20(dep).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for DEP
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, dep, _wavax.div(2)); 
        }      

        /// @dev In the case of DEP Rewards, swap half DEP for WAVAX
         if(_dep > 0){
            IERC20(dep).safeApprove(pangolinRouter, 0);
            IERC20(dep).safeApprove(pangolinRouter, _dep.div(2));   
            _swapPangolin(dep, wavax, _dep.div(2)); 
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and DEP
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > DEP
            _swapBaseToToken(_png.div(2), png, dep);    
        }

        /// @dev Add in liquidity for AVAX/DEP
        _wavax = IERC20(wavax).balanceOf(address(this));
        _dep = IERC20(dep).balanceOf(address(this));

        if (_wavax > 0 && _dep > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(dep).safeApprove(pangolinRouter, 0);
            IERC20(dep).safeApprove(pangolinRouter, _dep);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                dep,
                _wavax,
                _dep,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _dep = IERC20(dep).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_dep > 0){
                IERC20(dep).safeTransfer(
                    IController(controller).treasury(),
                    _dep
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
        return "StrategyPngAvaxDep";
    }
}