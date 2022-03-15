pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/BRIBE Liquidity Pool with PNG and LOOT rewards
contract StrategyPngAvaxBribe is StrategyPngMiniChefFarmBase {
    // LP and Token addresses
    uint256 public _poolId = 85;
    address public png_avax_bribe_lp = 0x7472887De3B0aA65168a1Da22164C81DE5fd4044;
    
    address public bribe = 0xCe2fbed816E320258161CeD52c2d0CEBcdFd8136;
    address public loot = 0x7f041ce89A2079873693207653b24C15B5e6A293;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_bribe_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice Fee path for LOOT must go through PNG
    function _takeFeeLootToSnob(uint256 _keep) internal {
        address[] memory path = new address[](4);
        path[0] = loot;
        path[1] = png;
        path[2] = wavax;
        path[3] = snob;
        IERC20(loot).safeApprove(pangolinRouter, 0);
        IERC20(loot).safeApprove(pangolinRouter, _keep);
        _swapPangolinWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    /// @notice Swap path for LOOT must go through PNG
    function _swapLootToToken(uint256 _amount, address token1, address token2) internal {
        address[] memory path;
        if (token1 == wavax || token2 == wavax) {
            path = new address[](3);
            path[0] = token1;
            path[1] = png;
            path[2] = token2;
        } 
        else {
            path = new address[](4);
            path[0] = token1;
            path[1] = png;
            path[2] = wavax;
            path[3] = token2;
        }
        IERC20(token1).safeApprove(pangolinRouter, 0);
        IERC20(token1).safeApprove(pangolinRouter, _amount);
        _swapPangolinWithPath(path, _amount);
    }

    /// @notice Collect token fees and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)  
        uint256 _avax = address(this).balance;              
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }

        // Check token balances, take fee for each token, then update balances
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _bribe = IERC20(bribe).balanceOf(address(this));
        uint256 _loot = IERC20(loot).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_bribe > 0) {
            uint256 _keep = _bribe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, bribe);
            }  

            _bribe = IERC20(bribe).balanceOf(address(this));
        }

        if (_loot > 0) {
            uint256 _keep = _loot.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeLootToSnob(_keep);
            }  

            _loot = IERC20(loot).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        // In the case of AVAX Rewards, swap half WAVAX for BRIBE
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, bribe, _wavax.div(2)); 
        }      

        // In the case of BRIBE Rewards, swap half BRIBE for WAVAX
         if(_bribe > 0){
            IERC20(bribe).safeApprove(pangolinRouter, 0);
            IERC20(bribe).safeApprove(pangolinRouter, _bribe.div(2));   
            _swapPangolin(bribe, wavax, _bribe.div(2)); 
        }

        // In the case of LOOT Rewards, swap LOOT for WAVAX and BRIBE
        if(_loot > 0){
            IERC20(loot).safeApprove(pangolinRouter, 0);
            IERC20(loot).safeApprove(pangolinRouter, _loot);   
            // Force path LOOT > PNG > WAVAX > BRIBE
            _swapLootToToken(_loot.div(2), loot, wavax);
            _swapLootToToken(_loot.div(2), loot, bribe);    
        }

        // In the case of PNG Rewards, swap PNG for WAVAX and BRIBE
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            // Force path PNG > WAVAX > BRIBE
            _swapBaseToToken(_png.div(2), png, bribe);    
        }

        // Add in liquidity for AVAX/BRIBE
        _wavax = IERC20(wavax).balanceOf(address(this));
        _bribe = IERC20(bribe).balanceOf(address(this));

        if (_wavax > 0 && _bribe > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(bribe).safeApprove(pangolinRouter, 0);
            IERC20(bribe).safeApprove(pangolinRouter, _bribe);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                bribe,
                _wavax,
                _bribe,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _bribe = IERC20(bribe).balanceOf(address(this));
            _loot = IERC20(loot).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }          
            
            if (_bribe > 0){
                IERC20(bribe).safeTransfer(
                    IController(controller).treasury(),
                    _bribe
                );
            }

            if (_loot > 0){
                IERC20(loot).safeTransfer(
                    IController(controller).treasury(),
                    _loot
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
        return "StrategyPngAvaxBribe";
    }
}