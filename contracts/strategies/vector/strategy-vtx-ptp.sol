// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-vtx-single-farm.sol";

contract StrategyVtxPtp is StrategyVtxSingleSidedFarmBase{

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyVtxSingleSidedFarmBase(
        ptp,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
       
    {}

    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IMasterChefVTX(masterchefvtx).deposit(xptp, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _vtx = IERC20(vtx).balanceOf(address(this));      // get balance of VTX Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  // get balance of AVAX Tokens

        // In the case of VTX Rewards, swap for PTP 
        if (_vtx > 0) {
            uint256 _keep = _vtx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, vtx);
            }
            
            _vtx = IERC20(vtx).balanceOf(address(this));

            IERC20(vtx).safeApprove(joeRouter, 0);
            IERC20(vtx).safeApprove(joeRouter, _vtx);   
            _swapTraderJoe(vtx, ptp, _vtx); 
        }

        // In the case of AVAX Rewards, swap for PTP
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, wavax);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);   
            _swapTraderJoe(wavax, ptp, _wavax); 
        }

        // Donates DUST
        _vtx = IERC20(vtx).balanceOf(address(this));
        _wavax = IERC20(wavax).balanceOf(address(this));
        if (_vtx > 0){
            IERC20(vtx).transfer(
                IController(controller).treasury(),
                _vtx
            );
        }
        
        if (_wavax > 0){
            IERC20(wavax).safeTransfer(
                IController(controller).treasury(),
                _wavax
            );
        }  

        _distributePerformanceFeesAndDeposit();
    }

     // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyVtxPtp";
    }
}