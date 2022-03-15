// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/FLY Liquidity Pool with JOE and FLY rewards
contract StrategyJoeAvaxFly is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 59;
    address public joe_avax_fly_lp = 0x1371a6d8CBe2Ca66d0911f270e1cAA7C12A3045A;
    
    address public fly = 0x78Ea3fef1c1f07348199Bf44f45b803b9B0Dbe28;
    
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
            joe_avax_fly_lp,
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
        uint256 _fly = IERC20(fly).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_fly > 0) {
            uint256 _keep = _fly.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, fly);
            }
            
            _fly = IERC20(fly).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for FLY
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, fly, _wavax.div(2)); 
        }

        // In the case of FLY Rewards, swap half FLY for WAVAX
        if(_fly > 0){
            IERC20(fly).safeApprove(joeRouter, 0);
            IERC20(fly).safeApprove(joeRouter, _fly.div(2));   
            _swapTraderJoe(fly, wavax, _fly.div(2)); 
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and FLY
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, fly, _joe.div(2));
        }
        
        // Add liquidity for AVAX/FLY
        _wavax = IERC20(wavax).balanceOf(address(this));
        _fly = IERC20(fly).balanceOf(address(this));
        if (_wavax > 0 && _fly > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(fly).safeApprove(joeRouter, 0);
            IERC20(fly).safeApprove(joeRouter, _fly);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                fly,
                _wavax,
                _fly,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _fly = IERC20(fly).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_fly > 0){
                IERC20(fly).safeTransfer(
                    IController(controller).treasury(),
                    _fly
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
        return "StrategyJoeAvaxFly";
    }
}