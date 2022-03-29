// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-vtx-farm-base.sol";

contract StrategyVtxUsdtE is StrategyVtxFarmBase{
    address public usdte = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public usdte_staking = 0x834eed8B99463A5d58B4D4B3a16b5904c37D7A2e; 
    address public usdte_rewarder = 0xF98578C210C8c7d9cBE8624Db9052d4F861aF3aC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyVtxFarmBase(
        usdte_rewarder,
        usdte_staking, 
        usdte,
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
        
        // In the case of VTX Rewards, swap VTX for USDTE
        if (_vtx > 0) {
            uint256 _keep = _vtx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, vtx);
            }
            
            _vtx = IERC20(vtx).balanceOf(address(this));

            IERC20(vtx).safeApprove(joeRouter, 0);
            IERC20(vtx).safeApprove(joeRouter, _vtx);   
            _swapTraderJoe(vtx, usdte, _vtx); 
        }
        
        // In the case of PTP Rewards, swap PTP for USDTE
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

            _swapTraderJoe(ptp, usdte, _ptp);
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
        return "StrategyVtxUsdtE";
    }
}