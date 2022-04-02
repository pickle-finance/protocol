// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-vtx-farm-base-lp.sol";

/// @notice This is the strategy for Vector Finance's staking with VTX, yielding VTX and XPTP tokens as rewards
contract StrategyVtxVtx is StrategyVtxLPFarmBase{
    address public vtx_staking = 0x423D0FE33031aA4456a17b150804aA57fc157d97; 
    address public xptp = 0x060556209E507d30f2167a101bFC6D256Ed2f3e1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyVtxLPFarmBase(
        vtx_staking,
        vtx,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
       
    {}

    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IMasterChefVTX(vtx_staking).deposit(vtx, 0);

        // Wraps native AVAX into WAVAX   
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _vtx = IERC20(vtx).balanceOf(address(this));            // get balance of VTX Tokens
        uint256 _xptp = IERC20(xptp).balanceOf(address(this));          // get balance of xPTP Tokens

        // In the case of VTX Rewards take fee and redeposit the remainder 
        if (_vtx > 0) {
            uint256 _keep = _vtx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, vtx);
            }
        }

        // In the case of xPTP Rewards, swap for VTX
        if (_xptp > 0) {
            uint256 _keep = _xptp.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, xptp);
            }
        
            _xptp = IERC20(xptp).balanceOf(address(this));

            IERC20(xptp).safeApprove(joeRouter, 0);
            IERC20(xptp).safeApprove(joeRouter, _xptp);   
            _swapTraderJoe(xptp, vtx, _xptp); 
        }
        _vtx = IERC20(vtx).balanceOf(address(this));

        // Donates DUST
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        _xptp = IERC20(xptp).balanceOf(address(this)); 
        if (_xptp > 0){
            IERC20(xptp).transfer(
                IController(controller).treasury(),
                _xptp
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
        return "StrategyVtxVtx";
    }
}