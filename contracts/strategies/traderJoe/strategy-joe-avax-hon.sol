// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxHon is StrategyJoeRushFarmBase {

    uint256 public avax_hon_poolId = 46;

    address public joe_avax_hon_lp = 0xDB87ba23c60e5fe6514f352A30b1170494045221;
    address public hon = 0xEd2b42D3C9c6E97e11755BB37df29B6375ede3EB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_hon_poolId,
            joe_avax_hon_lp,
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
        uint256 _hon = IERC20(hon).balanceOf(address(this));    // get balance of HON 
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_hon > 0) {
            uint256 _keep = _hon.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, hon);
            }
            
            _hon = IERC20(hon).balanceOf(address(this));
        }

        if (_joe > 0) {
            
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of WAVAX Rewards, swap half WAVAX for HON
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, hon, _wavax.div(2));
        }

        // In the case of HON Rewards, swap half HON for WAVAX
        if(_hon > 0){
            IERC20(hon).safeApprove(joeRouter, 0);
            IERC20(hon).safeApprove(joeRouter, _hon.div(2));   
            _swapTraderJoe(hon, wavax, _hon.div(2));
          
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and HON        
        if(_joe > 0){    
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, hon, _joe.div(2));
        }

        // Adds in liquidity for AVAX/HON
        _wavax = IERC20(wavax).balanceOf(address(this));
        _hon = IERC20(hon).balanceOf(address(this));

        if (_wavax > 0 && _hon > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(hon).safeApprove(joeRouter, 0);
            IERC20(hon).safeApprove(joeRouter, _hon);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                hon,
                _wavax,
                _hon,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _hon = IERC20(hon).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_hon > 0){
                IERC20(hon).safeTransfer(
                    IController(controller).treasury(),
                    _hon
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
        return "StrategyJoeAvaxHon";
    }
}