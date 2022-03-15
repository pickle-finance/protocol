pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/DLAUNCH Liquidity Pool with PNG and DLAUNCH rewards
contract StrategyPngUstDlaunch is StrategyPngMiniChefFarmBase {
    // LP and Token addresses
    uint256 public _poolId = 88;
    address public png_avax_dlaunch_lp = 0x7e6BC3A57fBcbAb72b0CbB4B2eCBAdD26373593F;
    
    address public ust = 0x260Bbf5698121EB85e7a74f2E45E16Ce762EbE11;
    address public dlaunch = 0x0659133127749Cc0616Ed6632912ddF7cc8D7545;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_dlaunch_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice Force UST and Dlaunch to swap directly for each other as _swapPangolin() path goes through PNG
    function _swapToken1ToToken2(uint256 _amount, address token1, address token2) internal {
        address[] memory path;
            path = new address[](2);
            path[0] = token1;
            path[1] = token2;
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
        uint256 _ust = IERC20(ust).balanceOf(address(this));
        uint256 _dlaunch = IERC20(dlaunch).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        if (_ust > 0) {
            uint256 _keep = _ust.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ust);
            }  

            _ust = IERC20(ust).balanceOf(address(this));
        }

        if (_dlaunch > 0) {
            uint256 _keep = _dlaunch.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, dlaunch);
            }  

            _dlaunch = IERC20(dlaunch).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        // In the case of UST Rewards, swap half UST for DLAUNCH
        if(_ust > 0){
            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust.div(2));   
            _swapToken1ToToken2(_ust.div(2), ust, dlaunch);
        }      

        // In the case of DLAUNCH Rewards, swap half DLAUNCH for UST
         if(_dlaunch > 0){
            IERC20(dlaunch).safeApprove(pangolinRouter, 0);
            IERC20(dlaunch).safeApprove(pangolinRouter, _dlaunch.div(2));   
            _swapToken1ToToken2(_dlaunch.div(2), dlaunch, ust);
        }

        // In the case of PNG Rewards, swap PNG for UST and DLAUNCH
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            // Force path PNG > WAVAX > DLAUNCH
            _swapBaseToToken(_png.div(2), png, ust);
            _swapBaseToToken(_png.div(2), png, dlaunch);
        }

        // In the case of WAVAX Rewards, swap WAVAX for UST and DLAUNCH
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);   
            _swapPangolin(wavax, ust, _wavax.div(2));
            _swapPangolin(wavax, dlaunch, _wavax.div(2));
        }

        // Add in liquidity for UST/DLAUNCH
        _ust = IERC20(ust).balanceOf(address(this));
        _dlaunch = IERC20(dlaunch).balanceOf(address(this));

        if (_ust > 0 && _dlaunch > 0) {
            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);

            IERC20(dlaunch).safeApprove(pangolinRouter, 0);
            IERC20(dlaunch).safeApprove(pangolinRouter, _dlaunch);

            IPangolinRouter(pangolinRouter).addLiquidity(
                ust,
                dlaunch,
                _ust,
                _dlaunch,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _ust = IERC20(ust).balanceOf(address(this));
            _dlaunch = IERC20(dlaunch).balanceOf(address(this));            
            _png = IERC20(png).balanceOf(address(this));
            _wavax = IERC20(wavax).balanceOf(address(this));
                      
            if (_ust > 0){
                IERC20(ust).safeTransfer(
                    IController(controller).treasury(),
                    _ust
                );
            }

            if (_dlaunch > 0){
                IERC20(dlaunch).safeTransfer(
                    IController(controller).treasury(),
                    _dlaunch
                );
            }

            if (_png > 0){
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
        }
    
        _distributePerformanceFeesAndDeposit();
    }

    /// @notice **** Views ****
    function getName() external pure override returns (string memory) {
        return "StrategyPngUstDlaunch";
    }
}