// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxUsdc is StrategyJoeRushFarmBase {

    uint256 public avax_usdc_poolId = 50;

    address public joe_avax_usdc_lp = 0xf4003F4efBE8691B60249E6afbD307aBE7758adb;
    address public usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_usdc_poolId,
            joe_avax_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Token Fees
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        // 10% is sent to treasury
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));  // get balance of WAVAX
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));    // get balance of USDC 
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_usdc > 0) {
            uint256 _keep = _usdc.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, usdc);
            }
            
            _usdc = IERC20(usdc).balanceOf(address(this));
        }

        if (_joe > 0) {
            
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of WAVAX Rewards, swap half WAVAX for USDC
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, usdc, _wavax.div(2));
        }

        // In the case of USDC Rewards, swap half USDC for WAVAX
        if(_usdc > 0){
            IERC20(usdc).safeApprove(joeRouter, 0);
            IERC20(usdc).safeApprove(joeRouter, _usdc.div(2));   
            _swapTraderJoe(usdc, wavax, _usdc.div(2));
          
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and USDC        
        if(_joe > 0){    
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
           _swapTraderJoe(joe, usdc, _joe.div(2));
        }

        // Adds in liquidity for AVAX/USDC
        _wavax = IERC20(wavax).balanceOf(address(this));
        _usdc = IERC20(usdc).balanceOf(address(this));

        if (_wavax > 0 && _usdc > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(usdc).safeApprove(joeRouter, 0);
            IERC20(usdc).safeApprove(joeRouter, _usdc);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                usdc,
                _wavax,
                _usdc,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _usdc = IERC20(usdc).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_usdc > 0){
                IERC20(usdc).safeTransfer(
                    IController(controller).treasury(),
                    _usdc
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
        return "StrategyJoeAvaxUsdc";
    }
}