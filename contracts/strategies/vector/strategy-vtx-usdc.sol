// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-vtx-farm-base.sol";

contract StrategyVtxUsdc is StrategyVtxFarmBase{
    address public usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public usdc_staking = 0x994F0e36ceB953105D05897537BF55d201245156; 
    address public usdc_rewarder = 0x145fF33FbEf61e87D9E033AB86AB38a7acC04C2E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyVtxFarmBase(
        usdc_rewarder, 
        usdc_staking, 
        usdc,
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
        
        // In the case of VTX Rewards, swap VTX for USDC
        if (_vtx > 0) {
            uint256 _keep = _vtx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, vtx);
            }
            
            _vtx = IERC20(vtx).balanceOf(address(this));

            IERC20(vtx).safeApprove(joeRouter, 0);
            IERC20(vtx).safeApprove(joeRouter, _vtx);   
            _swapTraderJoe(vtx, usdc, _vtx); 
        }
        
        // In the case of PTP Rewards, swap PTP for USDC
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

            _swapTraderJoe(ptp, usdc, _ptp);
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
        return "StrategyVtxUsdc";
    }
}