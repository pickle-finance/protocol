// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's PNG/UST (Wormhole) Liquidity Pool with PNG and UST rewards
contract StrategyPngUstWPng is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 101;

    // Token addresses
    address public png_ust_png_lp = 0x2a0f65C76008EcBC469b0850454E57310E770557;
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
            png_ust_png_lp,
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

        // Get balance of UST tokens and swap to PNG
        uint256 _ust = IERC20(ust).balanceOf(address(this));
        if (_ust > 0) {
            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);   
            _swapPangolin(ust, png, _ust);
        }     
        
        // Get the balance of PNG tokens, take fee, and swap half to UST
        uint256 _png = IERC20(png).balanceOf(address(this));        
        if (_png > 0){
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png.div(2));
            _swapPangolin(png, ust, _png.div(2));
        }

        // Add liquidity for PNG/UST
        _png = IERC20(png).balanceOf(address(this));
        _ust = IERC20(ust).balanceOf(address(this));

        if (_png > 0 && _ust > 0) {
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);

            IPangolinRouter(pangolinRouter).addLiquidity(
                png,
                ust,
                _png,
                _ust,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate DUST to the treasury
            _ust = IERC20(ust).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
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
        return "StrategyPngUstWPng";
    }
}