// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-vtx-farm-base.sol";

contract StrategyVtxDaiE is StrategyVtxFarmBase{
    address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address public daiE_staking = 0xC1ac7D1405b87259B8D380e0041d0573fb0AcB8c; 
    address public daiE_rewarder = 0x42FF74b00B57b8e087CF60cDfAe27EE4Df11b0ca;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyVtxFarmBase(
        daiE_rewarder, 
        daiE_staking, 
        daiE,
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

        // In the case of VTX Rewards, swap VTX for DAIE
        if (_vtx > 0) {
            uint256 _keep = _vtx.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, vtx);
            }
            
            _vtx = IERC20(vtx).balanceOf(address(this));

            IERC20(vtx).safeApprove(joeRouter, 0);
            IERC20(vtx).safeApprove(joeRouter, _vtx);   
            _swapTraderJoe(vtx, daiE, _vtx); 
        }
        
        // In the case of PTP Rewards, swap PTP for DAIE
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

            _swapTraderJoe(ptp, daiE, _ptp);
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
        return "StrategyVtxDaiE";
    }
}