// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxDomi is StrategyJoeRushFarmBase {

    uint256 public avax_domi_poolId = 47;

    address public joe_avax_domi_lp = 0x5B9Faf0feA95df4D4cB894Ef920704daFf656f3E;
    address public domi = 0xFc6Da929c031162841370af240dEc19099861d3B;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_domi_poolId,
            joe_avax_domi_lp,
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
        uint256 _domi = IERC20(domi).balanceOf(address(this));    // get balance of DOMI 
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_domi > 0) {
            uint256 _keep = _domi.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, domi);
            }
            
            _domi = IERC20(domi).balanceOf(address(this));
        }

        if (_joe > 0) {
            
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of WAVAX Rewards, swap half WAVAX for DOMI
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, domi, _wavax.div(2));
        }

        // In the case of DOMI Rewards, swap half DOMI for WAVAX
        if(_domi > 0){
            IERC20(domi).safeApprove(joeRouter, 0);
            IERC20(domi).safeApprove(joeRouter, _domi.div(2));   
            _swapTraderJoe(domi, wavax, _domi.div(2));
          
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and DOMI        
        if(_joe > 0){    
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, domi, _joe.div(2));
        }

        // Adds in liquidity for AVAX/DOMI
        _wavax = IERC20(wavax).balanceOf(address(this));
        _domi = IERC20(domi).balanceOf(address(this));

        if (_wavax > 0 && _domi > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(domi).safeApprove(joeRouter, 0);
            IERC20(domi).safeApprove(joeRouter, _domi);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                domi,
                _wavax,
                _domi,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _domi = IERC20(domi).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_domi > 0){
                IERC20(domi).safeTransfer(
                    IController(controller).treasury(),
                    _domi
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
        return "StrategyJoeAvaxDomi";
    }
}