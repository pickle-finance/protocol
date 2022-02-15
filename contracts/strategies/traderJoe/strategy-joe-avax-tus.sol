// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxTus is StrategyJoeRushFarmBase {

    uint256 public avax_tus_poolId = 48;

    address public joe_avax_tus_lp = 0x565d20BD591b00EAD0C927e4b6D7DD8A33b0B319;
    address public tus = 0xf693248F96Fe03422FEa95aC0aFbBBc4a8FdD172;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_tus_poolId,
            joe_avax_tus_lp,
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
        uint256 _tus = IERC20(tus).balanceOf(address(this));    // get balance of TUS 
        uint256 _joe = IERC20(joe).balanceOf(address(this));      // get balance of JOE 
        
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_tus > 0) {
            uint256 _keep = _tus.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeRewardToSnob(_keep, tus);
            }
            
            _tus = IERC20(tus).balanceOf(address(this));
        }

        if (_joe > 0) {
            
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));
        }

        // In the case of WAVAX Rewards, swap half WAVAX for TUS
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, tus, _wavax.div(2));
        }

        // In the case of TUS Rewards, swap half TUS for WAVAX
        if(_tus > 0){
            IERC20(tus).safeApprove(joeRouter, 0);
            IERC20(tus).safeApprove(joeRouter, _tus.div(2));   
            _swapTraderJoe(tus, wavax, _tus.div(2));
          
        }

        // In the case of JOE Rewards, swap JOE for WAVAX and TUS        
        if(_joe > 0){    
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);
            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, tus, _joe.div(2));
        }

        // Adds in liquidity for AVAX/TUS
        _wavax = IERC20(wavax).balanceOf(address(this));
        _tus = IERC20(tus).balanceOf(address(this));

        if (_wavax > 0 && _tus > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(tus).safeApprove(joeRouter, 0);
            IERC20(tus).safeApprove(joeRouter, _tus);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                tus,
                _wavax,
                _tus,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _tus = IERC20(tus).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_tus > 0){
                IERC20(tus).safeTransfer(
                    IController(controller).treasury(),
                    _tus
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
        return "StrategyJoeAvaxTus";
    }
}