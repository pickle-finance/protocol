pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/BAVA Liquidity Pool with PNG and BAVA rewards
contract StrategyPngAvaxBava is StrategyPngMiniChefFarmBase {
    /// @dev LP and Token addresses
    uint256 public _poolId = 84;
    address public png_avax_bava_lp = 0xeB69651B7146F4A42EBC32B03785C3eEddE58Ee7;
    
    address public bava = 0xe19A1684873faB5Fb694CfD06607100A632fF21c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_bava_lp,
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
        uint256 _bava = IERC20(bava).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_bava > 0) {
            uint256 _keep = _bava.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, bava);
            }  

            _bava = IERC20(bava).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        /// @dev In the case of AVAX Rewards, swap half WAVAX for BAVA
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, bava, _wavax.div(2)); 
        }      

        /// @dev In the case of BAVA Rewards, swap half BAVA for WAVAX
         if(_bava > 0){
            IERC20(bava).safeApprove(pangolinRouter, 0);
            IERC20(bava).safeApprove(pangolinRouter, _bava.div(2));   
            _swapPangolin(bava, wavax, _bava.div(2)); 
        }

        /// @dev In the case of PNG Rewards, swap PNG for WAVAX and BAVA
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            /// @dev Force path PNG > WAVAX > BAVA
            _swapBaseToToken(_png.div(2), png, bava);    
        }

        /// @dev Add in liquidity for AVAX/BAVA
        _wavax = IERC20(wavax).balanceOf(address(this));
        _bava = IERC20(bava).balanceOf(address(this));

        if (_wavax > 0 && _bava > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(bava).safeApprove(pangolinRouter, 0);
            IERC20(bava).safeApprove(pangolinRouter, _bava);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                bava,
                _wavax,
                _bava,
                0,
                0,
                address(this),
                now + 60
            );

            /// @dev Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _bava = IERC20(bava).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_bava > 0){
                IERC20(bava).safeTransfer(
                    IController(controller).treasury(),
                    _bava
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
        return "StrategyPngAvaxBava";
    }
}