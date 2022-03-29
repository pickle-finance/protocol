// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-vtx-farm-base.sol";

contract StrategyVtxUsdt is StrategyVtxFarmBase{
    address public usdt = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address public usdt_staking = 0x5c6C7Bc771f9A4231AF8D5a463E6D495833011F0; 
    address public usdt_rewarder = 0x39532F44adBD6197d8C2198F6F54e71F6B046449;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyVtxFarmBase(
        usdt_rewarder, 
        usdt_staking, 
        usdt,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
       
    {}


    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IPoolHelper(poolHelper).getReward();

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _vtx = IERC20(vtx).balanceOf(address(this));      // get balance of VTX Tokens
        uint256 _ptp = IERC20(ptp).balanceOf(address(this));      //get balance of PTP Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  //get balance of PTP Tokens

        // In the case of AVAX Rewards, swap AVAX for USDT
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, wavax);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);   
            _swapTraderJoe(wavax, usdt, _wavax); 
        }
        
        // In the case of VTX Rewards, swap VTX for USDT
        if (_vtx > 0) {
            uint256 _keep = _vtx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, vtx);
            }
            
            _vtx = IERC20(vtx).balanceOf(address(this));

            IERC20(vtx).safeApprove(joeRouter, 0);
            IERC20(vtx).safeApprove(joeRouter, _vtx);   
            _swapTraderJoe(vtx, usdt, _vtx); 
        }
        
        // In the case of PTP Rewards, swap PTP for USDT
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

            _swapTraderJoe(ptp, usdt, _ptp);
        }


        // Donates DUST
        _vtx = IERC20(vtx).balanceOf(address(this));
        _ptp = IERC20(ptp).balanceOf(address(this));
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

        _distributePerformanceFeesAndDeposit();
    }
    
    // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyVtxUsdt";
    }
}