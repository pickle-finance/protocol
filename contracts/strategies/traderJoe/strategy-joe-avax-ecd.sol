// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

/// @notice The strategy contract for TraderJoe's AVAX/ECD Liquidity Pool with JOE and ECD rewards
contract StrategyJoeAvaxEcd is StrategyJoeRushFarmBase {
    // LP and Token addresses
    uint256 public lp_poolId = 53;
    address public joe_avax_ecd_lp = 0x218e6A0AD170460F93eA784FbcC92B57DF13316E;
    
    address public ecd = 0xeb8343D5284CaEc921F035207ca94DB6BAaaCBcd;
    
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
            joe_avax_ecd_lp,
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
        uint256 _ecd = IERC20(ecd).balanceOf(address(this)); 
        uint256 _joe = IERC20(joe).balanceOf(address(this)); 
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }
        
        if (_ecd > 0) {
            uint256 _keep = _ecd.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, ecd);
            }
            
            _ecd = IERC20(ecd).balanceOf(address(this));
        }

        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of AVAX Rewards, swap half WAVAX for ECD
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, ecd, _wavax.div(2)); 
        }

        // In the case of ECD Rewards, swap half ECD for WAVAX
        if(_ecd > 0){
            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd.div(2));   
            _swapTraderJoe(ecd, wavax, _ecd.div(2)); 
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and ECD
        if(_joe > 0){
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, ecd, _joe.div(2));
        }
        
        // Add liquidity for AVAX/ECD
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ecd = IERC20(ecd).balanceOf(address(this));
        if (_wavax > 0 && _ecd > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ecd,
                _wavax,
                _ecd,
                0,
                0,
                address(this),
                now + 60
            );

            // Check balances and donate dust to the treasury
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ecd = IERC20(ecd).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_ecd > 0){
                IERC20(ecd).safeTransfer(
                    IController(controller).treasury(),
                    _ecd
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

    /// @notice Return contract name
    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxEcd";
    }
}