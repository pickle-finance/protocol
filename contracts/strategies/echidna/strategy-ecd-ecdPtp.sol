// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../bases/strategy-ecd-farm-base.sol";

contract StrategyEcdecdPTP is StrategyEcdFarmBase{

    address public ecdPtp = 0xb2C5172E5C15aF6aDD1ec92e518A5Ea1c7DeD2ad;
    address public ecdPTP_staking = 0xc9AA91645C3a400246B9D16c8d648F5dcEC6d1c8; 

    uint256 ecdPTP_id = 2; 

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyEcdFarmBase(
        ecdPTP_staking,
        ecdPTP_id,
        ecdPtp,
        _governance,
        _strategist,
        _controller,
        _timelock
    ) 
      
    {}

    // **** State Mutations ****
    function harvest() public override onlyBenevolent {
        // Collects Reward tokens
        IMasterChef(ecdPTP_staking).deposit(ecdPTP_id, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;                   // get balance of native Avax
        if (_avax > 0) {                                         // wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _ecd = IERC20(ecd).balanceOf(address(this));              // get balance of ECD Tokens
        uint256 _ptp = IERC20(ptp).balanceOf(address(this));              // get balance of PTP Tokens

        // In the case of PTP Rewards, swap PTP for ECDPTP
        if(_ptp > 0){
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
            IERC20(ptp).safeApprove(joeRouter, _ptp);

            _swapTraderJoeWithPath(path, _ptp); 
        }
        
        // In the case of ECD Rewards, swap ECD for ECDPTP
        if (_ecd > 0) {
            // 10% is sent to treasury
            uint256 _keep = _ecd.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeRewardToSnob(_keep, ecd);
            }

            _ecd = IERC20(ecd).balanceOf(address(this));

            // there is no liquidity for ecdPtp so we have to force swap through ptp
            address[] memory path = new address[](4);
            path[0] = ecd;
            path[1] = wavax;
            path[2] = ptp; 
            path[3] = ecdPtp; 

            IERC20(ecd).safeApprove(joeRouter, 0);
            IERC20(ecd).safeApprove(joeRouter, _ecd);

            _swapTraderJoeWithPath(path, _ecd); 
        }

        // Donates DUST
        _ecd = IERC20(ecd).balanceOf(address(this));
        _ptp = IERC20(ptp).balanceOf(address(this));
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

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyEcdecdPTP";
    }
}