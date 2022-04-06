// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/LOST Liquidity Pool with JOE rewards
contract StrategyJoeAvaxLost is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 67;
    address public joe_avax_lost_lp = 0x9C396cF96319C8EF2b662Af57DEA6EE374b9959F;
    
    address public lost = 0x449674B82F05d498E126Dd6615a1057A9c088f2C;
    
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
            joe_avax_lost_lp,
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
        uint256 _lost = IERC20(lost).balanceOf(address(this));       
        // Swap LOST into WAVAX
        if(_lost > 0){
            IERC20(lost).safeApprove(joeRouter, 0);
            IERC20(lost).safeApprove(joeRouter, _lost);   
            _swapTraderJoe(lost, wavax, _lost); 
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
    
        // Swap half WAVAX for LOST
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, lost, _wavax.div(2)); 
        }
        
        // Add liquidity for AVAX/LOST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _lost = IERC20(lost).balanceOf(address(this));
        if (_wavax > 0 && _lost > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(lost).safeApprove(joeRouter, 0);
            IERC20(lost).safeApprove(joeRouter, _lost);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                lost,
                _wavax,
                _lost,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _lost = IERC20(lost).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_lost > 0){
                IERC20(lost).safeTransfer(
                    IController(controller).treasury(),
                    _lost
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
        return "StrategyJoeAvaxLost";
    }
}