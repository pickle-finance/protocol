// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeUsdcEUst is StrategyJoeRushFarmBase {

    uint256 public usdce_ust_poolId = 49;

    address public joe_usdce_ust_lp = 0xA3A029224857bF467E896523E268a5fc005Ce810;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public ust = 0x260Bbf5698121EB85e7a74f2E45E16Ce762EbE11;
//    address public usdte = 0x00;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            usdce_ust_poolId,
            joe_usdce_ust_lp,
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
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));  // get balance of USDCe
        uint256 _ust = IERC20(ust).balanceOf(address(this));      // get balance of UST  
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_usdce > 0) {
            uint256 _keep = _usdce.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, usdce);
            }
            
            _usdce = IERC20(usdce).balanceOf(address(this));
        }

        if (_ust > 0) {
            uint256 _keep = _ust.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, ust);
            }
            
            _ust = IERC20(ust).balanceOf(address(this));
        }

        if (_joe > 0) {
            
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of WAVAX Rewards, swap WAVAX for USDCe and UST
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);   
            _swapTraderJoe(wavax, usdce, _wavax.div(2));
            _swapTraderJoe(wavax, ust, _wavax.div(2));
        }

        // In the case of USDCe Rewards, swap half USDCe for UST
        if(_usdce > 0){
            IERC20(usdce).safeApprove(joeRouter, 0);
            IERC20(usdce).safeApprove(joeRouter, _usdce.div(2));   
            _swapTraderJoe(usdce, ust, _usdce.div(2));  
        }

        // In the case of UST Rewards, swap half UST for USDCe
        if(_ust > 0){
            IERC20(ust).safeApprove(joeRouter, 0);
            IERC20(ust).safeApprove(joeRouter, _ust.div(2));   
            _swapTraderJoe(ust, usdce, _ust.div(2)); 
        }

        // In the case of JOE Rewards, swap JOE for USDCe and UST        
        if(_joe > 0){    
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, usdce, _joe.div(2));
            _swapTraderJoe(joe, ust, _joe.div(2));  
        }

        // Adds in liquidity for USDCe/UST
        _usdce = IERC20(usdce).balanceOf(address(this));
        _ust = IERC20(ust).balanceOf(address(this));

        if (_usdce > 0 && _ust > 0) {
            IERC20(usdce).safeApprove(joeRouter, 0);
            IERC20(usdce).safeApprove(joeRouter, _usdce);

            IERC20(ust).safeApprove(joeRouter, 0);
            IERC20(ust).safeApprove(joeRouter, _ust);

            IJoeRouter(joeRouter).addLiquidity(
                usdce,
                ust,
                _usdce,
                _ust,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _usdce = IERC20(usdce).balanceOf(address(this));
            _ust = IERC20(ust).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_usdce > 0){
                IERC20(usdce).safeTransfer(
                    IController(controller).treasury(),
                    _usdce
                );
            } 

            if (_ust > 0){
                IERC20(ust).safeTransfer(
                    IController(controller).treasury(),
                    _ust
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
        return "StrategyJoeUsdcEUst";
    }
}