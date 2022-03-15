// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/DEG Liquidity Pool with JOE and DEG rewards
contract StrategyJoeAvaxDeg is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 60;
    address public joe_avax_deg_lp = 0x465460F46969F2bf969432956491dEE95A6ba493;
    
    address public deg = 0x9f285507Ea5B4F33822CA7aBb5EC8953ce37A645;
    
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
            joe_avax_deg_lp,
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
        uint256 _deg = IERC20(deg).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_deg > 0) {
            uint256 _keep = _deg.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, deg);
            }
            
            _deg = IERC20(deg).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for DEG
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, deg, _wavax.div(2)); 
        }

        // In the case of DEG Rewards, swap half DEG for WAVAX
        if(_deg > 0){
            IERC20(deg).safeApprove(joeRouter, 0);
            IERC20(deg).safeApprove(joeRouter, _deg.div(2));   
            _swapTraderJoe(deg, wavax, _deg.div(2)); 
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and DEG
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, deg, _joe.div(2));
        }
        
        // Add liquidity for AVAX/DEG
        _wavax = IERC20(wavax).balanceOf(address(this));
        _deg = IERC20(deg).balanceOf(address(this));
        if (_wavax > 0 && _deg > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(deg).safeApprove(joeRouter, 0);
            IERC20(deg).safeApprove(joeRouter, _deg);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                deg,
                _wavax,
                _deg,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _deg = IERC20(deg).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_deg > 0){
                IERC20(deg).safeTransfer(
                    IController(controller).treasury(),
                    _deg
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
        return "StrategyJoeAvaxDeg";
    }
}