// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

/// @notice The strategy contract for Pangolin's USDC/UST (Wormhole) Liquidity Pool with PNG and UST rewards
contract StrategyPngUsdcUstW is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 103;

    // Token addresses
    address public png_usdc_ust_lp = 0xE1f75E2E74BA938abD6C3BE18CCc5C7f71925C4B;
    address public usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
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
            png_usdc_ust_lp,
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

        // Get balance of reward tokens and swap to USDC
        uint256 _ust = IERC20(ust).balanceOf(address(this));
        if (_ust > 0) {
            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);   
            // Force swap path from UST > USDC
            address[] memory path;                      
            path = new address[](2);
            path[0] = ust;
            path[1] = usdc;
            _swapPangolinWithPath(path, _ust);
        }

        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapBaseToToken(_png, png, usdc);
        }          
        
        // Get the balance of USDC tokens, take fee, and swap half to UST
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));        
        if (_usdc > 0){
            uint256 _keep = _usdc.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, usdc);
            }

            _usdc = IERC20(usdc).balanceOf(address(this));
            IERC20(usdc).safeApprove(pangolinRouter, 0);
            IERC20(usdc).safeApprove(pangolinRouter, _usdc.div(2));
            // Force swap path from USDC > UST
            address[] memory path;
            path = new address[](2);
            path[0] = usdc;
            path[1] = ust;
            _swapPangolinWithPath(path, _usdc.div(2));
        }

        // Add liquidity for USDC/UST
        _usdc = IERC20(usdc).balanceOf(address(this));
        _ust = IERC20(ust).balanceOf(address(this));

        if (_usdc > 0 && _ust > 0) {
            IERC20(usdc).safeApprove(pangolinRouter, 0);
            IERC20(usdc).safeApprove(pangolinRouter, _usdc);

            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);

            IPangolinRouter(pangolinRouter).addLiquidity(
                usdc,
                ust,
                _usdc,
                _ust,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate DUST to the treasury
            _usdc = IERC20(usdc).balanceOf(address(this));
            _ust = IERC20(ust).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            if (_usdc > 0){
                IERC20(usdc).transfer(
                    IController(controller).treasury(),
                    _usdc
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
        return "StrategyPngUsdcUstW";
    }
}