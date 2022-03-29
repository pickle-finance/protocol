// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-ecd-farm-base.sol";

contract StrategyEcdPtpEcdPtp is StrategyEcdFarmBase{

    address public ptp_ecdptp = 0xc8898e2eEE8a1d08742bb3173311697966451F61;
    address public ecdPtp = 0xb2C5172E5C15aF6aDD1ec92e518A5Ea1c7DeD2ad;
    address public ptp_ecdPTP_staking = 0xc9AA91645C3a400246B9D16c8d648F5dcEC6d1c8; 

    uint256 ptp_ecdptp_id = 1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyEcdFarmBase(
        ptp_ecdPTP_staking,
        ptp_ecdptp_id,
        ptp_ecdptp,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
    
    {}

    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IMasterChef(ptp_ecdPTP_staking).deposit(ptp_ecdptp_id, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _ecd = IERC20(ecd).balanceOf(address(this));              // get balance of ECD Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));          // get balance of WAVAX Tokens

        // In the case of ECD Rewards, swap ECD for PTP 
        if (_ecd > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ecd.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ecd);
            }

            _ecd = IERC20(ecd).balanceOf(address(this));

            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd);

            _swapTraderJoe(ecd, ptp, _ecd); 
        }

        // In the case of AVAX Rewards, swap AVAX for PTP 
        if (_wavax > 0) {
            // 10% is sent to treasury
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, wavax);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            _swapTraderJoe(wavax, ptp, _wavax); 
        }

        uint256 _ptp = IERC20(ptp).balanceOf(address(this));              // get balance of PTP Tokens
        // swap half PTP for ecdPTP
        if (_ptp > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ptp.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ptp);
            }

            _ptp = IERC20(ptp).balanceOf(address(this));

            // there is no liquidity for ecdPtp so we have to force swap through ptp
            address[] memory path = new address[](2);
            path[0] = ptp;
            path[1] = ecdPtp; 

            IERC20(ptp).safeApprove(joeRouter, 0);
            IERC20(ptp).safeApprove(joeRouter, _ptp.div(2));

            _swapTraderJoeWithPath(path, _ptp.div(2));
        }

        // Adds in liquidity for PTP/ECDPTP
        _ptp = IERC20(ptp).balanceOf(address(this));
        uint256 _ecdPtp = IERC20(ecdPtp).balanceOf(address(this));

        if (_ptp > 0 && _ecdPtp > 0) {
            IERC20(ptp).safeApprove(joeRouter, 0);
            IERC20(ptp).safeApprove(joeRouter, _ptp);

            IERC20(ecdPtp).safeApprove(joeRouter, 0);
            IERC20(ecdPtp).safeApprove(joeRouter, _ecdPtp);

            IJoeRouter(joeRouter).addLiquidity(
                ptp,
                ecdPtp,
                _ptp,
                _ecdPtp,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _ecd = IERC20(ecd).balanceOf(address(this));
            _ptp = IERC20(ptp).balanceOf(address(this));
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ecdPtp = IERC20(ecdPtp).balanceOf(address(this));
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

            if (_ecdPtp > 0){
                IERC20(ecdPtp).safeTransfer(
                    IController(controller).treasury(),
                    _ecdPtp
                );
            }  
        }
        
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyEcdPtpEcdPtp";
    }
}