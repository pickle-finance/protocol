// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-vtx-farm-base-lp.sol";

contract StrategyVtxAvaxVtx is StrategyVtxLPFarmBase{
    address public avax_vtx = 0x9EF0C12b787F90F59cBBE0b611B82D30CAB92929;
    address public avax_vtx_staking = 0x423D0FE33031aA4456a17b150804aA57fc157d97; 

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyVtxLPFarmBase( 
        avax_vtx_staking,
        avax_vtx,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
       
    {}

    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IMasterChefVTX(avax_vtx_staking).deposit(avax_vtx, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _vtx = IERC20(vtx).balanceOf(address(this));      // get balance of VTX Tokens
        uint256 _ptp = IERC20(ptp).balanceOf(address(this));      //get balance of PTP Tokens
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  // get balance of AVAX Tokens

        // In the case of VTX Rewards, swap half for VTX for AVAX 
        if (_vtx > 0) {
            uint256 _keep = _vtx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, vtx);
            }
            
            _vtx = IERC20(vtx).balanceOf(address(this));

            IERC20(vtx).safeApprove(joeRouter, 0);
            IERC20(vtx).safeApprove(joeRouter, _vtx);   
            _swapTraderJoe(vtx, wavax, _vtx.div(2)); 
        }

        // In the case of AVAX Rewards, swap half for VTX
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, wavax);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);   
            _swapTraderJoe(wavax, vtx, _wavax.div(2)); 
        }

        // In the case of JOE Rewards, swap half for wavax and half for AVAX 
        if (_joe > 0) {
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, joe);
            }
            
            _joe = IERC20(joe).balanceOf(address(this));

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);   
            _swapTraderJoe(joe, wavax, _joe.div(2)); 
            _swapTraderJoe(joe, vtx, _joe.div(2));
        }
        
        // In the case of PTP Rewards, swap half PTP for AVAX and half for VTX
        _ptp = IERC20(ptp).balanceOf(address(this));
        if (_ptp > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ptp.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ptp);
            }
            _ptp = IERC20(ptp).balanceOf(address(this));

            IERC20(ptp).safeApprove(joeRouter, 0);
            IERC20(ptp).safeApprove(joeRouter, _ptp);

            _swapTraderJoe(ptp, wavax, _ptp.div(2));
            _swapTraderJoe(ptp, vtx, _ptp.div(2));
        }

        // Adds in liquidity for AVAX/VTX
        _wavax = IERC20(wavax).balanceOf(address(this));
        _vtx = IERC20(vtx).balanceOf(address(this));
        if (_wavax > 0 && _vtx > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(vtx).safeApprove(joeRouter, 0);
            IERC20(vtx).safeApprove(joeRouter, _vtx);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                vtx,
                _wavax,
                _vtx,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _vtx = IERC20(vtx).balanceOf(address(this));
            _ptp = IERC20(ptp).balanceOf(address(this));
            _wavax = IERC20(wavax).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this)); 
            if (_vtx > 0){
                IERC20(vtx).transfer(
                    IController(controller).treasury(),
                    _vtx
                );
            }
            
            if (_ptp > 0){
                IERC20(ptp).safeTransfer(
                    IController(controller).treasury(),
                    _ptp
                );
            }  
            
            if (_wavax > 0){
                IERC20(wavax).safeTransfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }  

            if (_joe > 0){
                IERC20(joe).transfer(
                    IController(controller).treasury(),
                    _joe
                );
            }
        }
 
        _distributePerformanceFeesAndDeposit();
    }
    
    // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyVtxAvaxVtx";
    }
}