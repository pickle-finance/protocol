// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/APE Liquidity Pool with JOE rewards
contract StrategyJoeAvaxApe is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 63;
    address public joe_avax_ape_lp = 0x11bBfA2Fa3b995ceA99D20DFA618fd32e252d8F2;
    
    address public ape = 0x0802d66f029c46E042b74d543fC43B6705ccb4ba;
    
    /// @notice Constructor
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            lp_poolId,
            joe_avax_ape_lp,
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
        
        // Check token balances, swap token into WAVAX
        uint256 _ape = IERC20(ape).balanceOf(address(this));       
        // Swap APE into WAVAX
        if(_ape > 0){
            IERC20(ape).safeApprove(joeRouter, 0);
            IERC20(ape).safeApprove(joeRouter, _ape);   
            _swapTraderJoe(ape, wavax, _ape); 
        }

        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        // Swap JOE for WAVAX 
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
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
    
        // Swap half WAVAX for APE
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, ape, _wavax.div(2)); 
        }
        
        // Add liquidity for AVAX/APE
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ape = IERC20(ape).balanceOf(address(this));
        if (_wavax > 0 && _ape > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ape).safeApprove(joeRouter, 0);
            IERC20(ape).safeApprove(joeRouter, _ape);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ape,
                _wavax,
                _ape,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ape = IERC20(ape).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_ape > 0){
                IERC20(ape).safeTransfer(
                    IController(controller).treasury(),
                    _ape
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

    /// @notice **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxApe";
    }
}