// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/UST (Wormhole) Liquidity Pool with Joe and UST rewards
contract StrategyJoeAvaxUstW is StrategyJoeRushFarmBase {
    // LP and Token contract addresses
    uint256 public avax_ust_poolId = 66;

    address public joe_avax_ust_lp = 0xeCD6D33555183Bc82264dbC8bebd77A1f02e421E;
    address public ust = 0xb599c3590F42f8F995ECfa0f85D2980B76862fc1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_ust_poolId,
            joe_avax_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    /// @notice Collect token fees, swap rewards, and add liquidity to base pair
    function harvest() public override onlyBenevolent {
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);
   
        // Get balance of native AVAX and wrap AVAX into ERC20 (WAVAX)
        uint256 _avax = address(this).balance;
        if (_avax > 0) {                                    
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        // Check token balances, swap tokens into WAVAX
        // Swap UST into WAVAX
        uint256 _ust = IERC20(ust).balanceOf(address(this));       
        if(_ust > 0){
            IERC20(ust).safeApprove(joeRouter, 0);
            IERC20(ust).safeApprove(joeRouter, _ust);   
            _swapTraderJoe(ust, wavax, _ust); 
        }
        
        // Swap JOE into WAVAX 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe);
        }

        // Take fee from WAVAX balance to SNOB
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
    
        // Swap half WAVAX for UST
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, ust, _wavax.div(2)); 
        }
        
        // Add liquidity for AVAX/UST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ust = IERC20(ust).balanceOf(address(this));
        if (_wavax > 0 && _ust > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ust).safeApprove(joeRouter, 0);
            IERC20(ust).safeApprove(joeRouter, _ust);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ust,
                _wavax,
                _ust,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ust = IERC20(ust).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
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

            if (_joe > 0){
                IERC20(joe).safeTransfer(
                    IController(controller).treasury(),
                    _joe
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    /// @notice Return the name of the strategy
    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxUstW";
    }
}