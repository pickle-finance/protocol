// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-ecd-farm-base.sol";

contract StrategyEcdAvaxEcd is StrategyEcdFarmBase{

    address public avax_ecd = 0x218e6A0AD170460F93eA784FbcC92B57DF13316E;
    address public avax_ecd_staking = 0xc9AA91645C3a400246B9D16c8d648F5dcEC6d1c8; 
    uint256 avax_ecd_id = 0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyEcdFarmBase(
        avax_ecd_staking,
        avax_ecd_id,
        avax_ecd,
        _governance,
        _strategist,
        _controller,
        _timelock
    )  
     
    {}

    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IMasterChef(avax_ecd_staking).deposit(avax_ecd_id, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _ecd = IERC20(ecd).balanceOf(address(this));              // get balance of ECD Tokens
        uint256 _ptp = IERC20(ptp).balanceOf(address(this));              // get balance of PTP Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));          // get balance of WAVAX Tokens

        // In the case of WAVAX Rewards, swap half for ECD
        if (_wavax > 0) {
            // 10% is sent to treasury
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, wavax);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            _swapTraderJoe(wavax, ecd, _wavax.div(2)); 
        }

        // In the case of ECD Rewards, swap half ECD for AVAX
        if (_ecd > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ecd.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ecd);
            }

            _ecd = IERC20(ecd).balanceOf(address(this));

            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd.div(2));

            _swapTraderJoe(ecd, wavax, _ecd.div(2)); 
        }

        // In the case of PTP Rewards, swap half for AVAX and half for ECD
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
            _swapTraderJoe(ptp, ecd, _ptp.div(2)); 
        }

        // Adds in liquidity for AVAX/ECD
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ecd = IERC20(ecd).balanceOf(address(this));

        if (_wavax > 0 && _ecd > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ecd,
                _wavax,
                _ecd,
                0,
                0,
                address(this),
                now + 60
            );

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
        }
        
        _distributePerformanceFeesAndDeposit();
    }
    
    // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyEcdAvaxEcd";
    }
}