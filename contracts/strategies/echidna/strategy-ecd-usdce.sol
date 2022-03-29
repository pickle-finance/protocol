// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-ecd-stable-farm-base.sol";

contract StrategyEcdUsdcE is StrategyStableFarmBase{ 

    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public lp_usdce = 0x909B0ce4FaC1A0dCa78F8Ca7430bBAfeEcA12871;

    address public usdce_reward_pool = 0xE0412fAA4195433de647cbD45B499F68c15c484d;
    uint256 usdce_id = 1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyStableFarmBase(
        usdce_reward_pool,
        lp_usdce,
        usdce_id,
        usdce,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
       
    {}

    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IRewardPool(usdce_reward_pool).getReward(address(this), true);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _ptp = IERC20(ptp).balanceOf(address(this));              // get balance of PTP Tokens
        uint256 _ecd = IERC20(ecd).balanceOf(address(this));              // get balance of ECD Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));          // get balance of WAVAX tokens

        // In the case of AVAX Rewards, swap for USDCE   
        if (_wavax > 0) {
            // 10% is sent to treasury
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, wavax);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            _swapTraderJoe(wavax, usdce, _wavax); 
        }

        // In the case of ECD Rewards, swap ECD for USDCE
        if (_ecd > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ecd.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ecd);
            }

            _ecd = IERC20(ecd).balanceOf(address(this));

            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd);

            _swapTraderJoe(ecd, usdce, _ecd); 
        }

        // In the case of PTP Rewards, swap for USDCE
        if (_ptp > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ptp.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ptp);
            }

            _ptp = IERC20(ptp).balanceOf(address(this));

            IERC20(ptp).safeApprove(joeRouter, 0);
            IERC20(ptp).safeApprove(joeRouter, _ptp);

            _swapTraderJoe(ptp, usdce, _ptp); 
        }

        // Donates DUST
        _ecd = IERC20(ecd).balanceOf(address(this));
        _ptp = IERC20(ptp).balanceOf(address(this));
        _wavax = IERC20(wavax).balanceOf(address(this));
        if (_ecd > 0){
            IERC20(ecd).safeTransfer(
                IController(controller).treasury(),
                _ecd
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

        _distributePerformanceFeesAndDeposit();
    }
    
    // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyEcdUsdcE";
    }
}