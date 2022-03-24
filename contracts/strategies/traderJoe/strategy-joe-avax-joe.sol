// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-joe-boost-farm.sol";

/// @notice This is the strategy contract for TraderJoe's Avax-Joe pair which reapos joe rewards
contract StrategyJoeAvaxJoe is StrategyJoeBoostFarmBase {
    
    // Token and LP contract addresses
    address public avaxJoeLp =  0x454E67025631C065d3cFAD6d71E6892f74487a15;

    uint256 public lpPoolId = 6; 

    constructor (
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public
    StrategyJoeBoostFarmBase(
        lpPoolId,
        avaxJoeLp, 
        _governance,
        _strategist,
        _controller,
        _timelock
    )
    {}

    ///@notice ** Harvest our rewards from masterchef **
    function harvest() public override onlyBenevolent {

        /// @param _pid is the pool id for the lp tokens
        /// @param _amount is the amount to be deposited into masterchef
        IMasterChefJoe(masterchefJoe).deposit(lpPoolId, 0);

        // ** Wraps any AVAX that might be present into wavax ** //
        uint256 _avax = address(this).balance;                 
        if (_avax > 0) {                                       
            WAVAX(wavax).deposit{value: _avax}();
        }

        // ** Swap all our reward tokens for wavax ** //
        uint256 _joe = IERC20(joe).balanceOf(address(this));            // get balance of joe tokens
        if(_joe > 0) {
            _swapToWavax(joe, _joe);
        }

        // ** Takes the fee and swaps for equal shares in our lp token ** // 
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));            
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax); 
            if (_keep > 0) {
               _takeFeeWavaxToSnob(_keep); 

               _wavax = IERC20(wavax).balanceOf(address(this));
               _swapTraderJoe(wavax, joe, _wavax.div(2));                     
            }
        }

        // ** Adds liqudity for the AVAX-joe LP ** ///
        _wavax = IERC20(wavax).balanceOf(address(this));
        _joe = IERC20(joe).balanceOf(address(this));
        if (_wavax > 0 && _joe > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            
            ///@dev see IJoeRouter contract for param definitions
            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                joe,
                _wavax,
                _joe,
                0,
                0,
                address(this),
                now + 60
            );
        }

        // ** Donates DUST ** // 
        _wavax = IERC20(wavax).balanceOf(address(this));
        _joe = IERC20(joe).balanceOf(address(this));
        if (_wavax > 0){
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                _wavax
            );
        }
        if (_joe > 0){
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _joe
            );
        }

        _distributePerformanceFeesAndDeposit();                 // redeposits lp 
    }

    // **** Views ****
    ///@notice returns the strategy name
    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxJoe";
    }
}