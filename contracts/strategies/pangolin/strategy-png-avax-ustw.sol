// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's AVAX/UST (Wormhole) Liquidity Pool with PNG and UST rewards
contract StrategyPngAvaxUstW is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 102;

    // Token addresses
    address public png_avax_ust_lp = 0x9D563afF8B0017868DbA57eB3E04298C157d0aF5;
    address public ust = 0xb599c3590F42f8F995ECfa0f85D2980B76862fc1;

    /// @notice constructor
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****
    /// @notice Collect token fees, swap rewards, and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Get balance of native AVAX and wrap into ERC20 (WAVAX)
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        // Get balance of reward tokens and swap to WAVAX
        uint256 _ust = IERC20(ust).balanceOf(address(this));
        if (_ust > 0) {
            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);   
            _swapPangolin(ust, wavax, _ust);
        }

        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png);
        }          
        
        // Get the balance of WAVAX tokens, take fee, and swap half to UST
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));        
        if (_wavax > 0){
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));
            _swapPangolin(wavax, ust, _wavax.div(2));
        }

        // Add liquidity for WAVAX/UST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ust = IERC20(ust).balanceOf(address(this));

        if (_wavax > 0 && _ust > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                ust,
                _wavax,
                _ust,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate DUST to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ust = IERC20(ust).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_ust > 0){
                IERC20(ust).safeTransfer(
                    IController(controller).treasury(),
                    _ust
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

    /// @notice Return the name of the strategy
    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxUstW";
    }
}