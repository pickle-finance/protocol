// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-ecd-stable-farm-base.sol";

contract StrategyEcdUsdtE is StrategyStableFarmBase{ 

    address public usdte = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public lp_usdte = 0x0D26D103c91F63052Fbca88aAF01d5304Ae40015;

    address public usdte_reward_pool = 0x6A3C5260Cc8eA990a0a122CE42d8E826698920E0;
    uint256 usdte_id = 0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyStableFarmBase(
        usdte_reward_pool,
        lp_usdte,
        usdte_id,
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
        IRewardPool(usdte_reward_pool).getReward(address(this), true);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _ptp = IERC20(ptp).balanceOf(address(this));              // get balance of PTP Tokens
        uint256 _ecd = IERC20(ecd).balanceOf(address(this));              // get balance of ECD Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));          // get balance of WAVAX tokens

        // In the case of AVAX Rewards, swap for USDTE   
        if (_wavax > 0) {
            // 10% is sent to treasury
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, wavax);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            _swapTraderJoe(wavax, usdte, _wavax); 
        }

        // In the case of ECD Rewards, swap ECD for USDTE
        if (_ecd > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ecd.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ecd);
            }

            _ecd = IERC20(ecd).balanceOf(address(this));

            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd);

            _swapTraderJoe(ecd, usdte, _ecd); 
        }

        // In the case of PTP Rewards, swap for USDTE   
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
        return "StrategyEcdUsdtE";
    }
}