// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/DFIAT Liquidity Pool with JOE and DFIAT rewards
contract StrategyJoeAvaxDfiat is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 58;
    address public joe_avax_dfiat_lp = 0x7Ca8e6a11466f8542f2b65B845C77D425182CbDe;
    
    address public dfiat = 0xAfE3d2A31231230875DEe1fa1eEF14a412443d22;
    
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
            joe_avax_dfiat_lp,
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
        
        // Check token balances, take fee for each token, then update balances
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _dfiat = IERC20(dfiat).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_dfiat > 0) {
            uint256 _keep = _dfiat.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, dfiat);
            }
            
            _dfiat = IERC20(dfiat).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for DFIAT
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, dfiat, _wavax.div(2)); 
        }

        // In the case of DFIAT Rewards, swap half DFIAT for WAVAX
        if(_dfiat > 0){
            IERC20(dfiat).safeApprove(joeRouter, 0);
            IERC20(dfiat).safeApprove(joeRouter, _dfiat.div(2));   
            _swapTraderJoe(dfiat, wavax, _dfiat.div(2)); 
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and DFIAT
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, dfiat, _joe.div(2));
        }
        
        // Add liquidity for AVAX/DFIAT
        _wavax = IERC20(wavax).balanceOf(address(this));
        _dfiat = IERC20(dfiat).balanceOf(address(this));
        if (_wavax > 0 && _dfiat > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(dfiat).safeApprove(joeRouter, 0);
            IERC20(dfiat).safeApprove(joeRouter, _dfiat);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                dfiat,
                _wavax,
                _dfiat,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _dfiat = IERC20(dfiat).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_dfiat > 0){
                IERC20(dfiat).safeTransfer(
                    IController(controller).treasury(),
                    _dfiat
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
        return "StrategyJoeAvaxDfiat";
    }
}