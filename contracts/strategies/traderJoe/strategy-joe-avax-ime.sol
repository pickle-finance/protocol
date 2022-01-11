// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-rush-farm-base.sol";

contract StrategyJoeAvaxIme is StrategyJoeRushFarmBase {

    uint256 public avax_ime_poolId = 30;

    address public joe_avax_ime_lp = 0x5d95ae932D42E53Bb9DA4DE65E9b7263A4fA8564;
    address public ime = 0xF891214fdcF9cDaa5fdC42369eE4F27F226AdaD6;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeRushFarmBase(
            avax_ime_poolId,
            joe_avax_ime_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeImeToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = ime;
        path[1] = wavax;
        path[2] = snob;
        IERC20(ime).safeApprove(joeRouter, 0);
        IERC20(ime).safeApprove(joeRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV3).deposit(poolId, 0);

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }
        
        uint256 _ime = IERC20(ime).balanceOf(address(this));   //get balance of IME Tokens
        uint256 _wavax = IERC20(wavax).balanceOf(address(this)); //get balance of WAVAX
        if (_wavax > 0) {
            uint256 _keep1 = _wavax.mul(keep).div(keepMax);
            if (_keep1 > 0){
                _takeFeeWavaxToSnob(_keep1);
            }
            
            _wavax = IERC20(wavax).balanceOf(address(this));

        }

         if (_ime > 0) {
            uint256 _keep2 = _ime.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeImeToSnob(_keep2);
            }
            
            _ime = IERC20(ime).balanceOf(address(this));
          
        }

        // In the case of IME Rewards, swap IME for WAVAX
        if(_ime > 0){
            IERC20(ime).safeApprove(joeRouter, 0);
            IERC20(ime).safeApprove(joeRouter, _ime.div(2));   
            _swapTraderJoe(ime, wavax, _ime.div(2));
        }

        // In the case of AVAX Rewards, swap WAVAX for IME
        if(_wavax > 0){
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.div(2));   
            _swapTraderJoe(wavax, ime, _wavax.div(2)); 
        }

        
        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }

            _joe = IERC20(joe).balanceOf(address(this));

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);

            _swapTraderJoe(joe, wavax, _joe.div(2));
            _swapTraderJoe(joe, ime, _joe.div(2));
        }

        // Adds in liquidity for AVAX/IME
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ime = IERC20(ime).balanceOf(address(this));

        if (_wavax > 0 && _ime > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(ime).safeApprove(joeRouter, 0);
            IERC20(ime).safeApprove(joeRouter, _ime);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                ime,
                _wavax,
                _ime,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ime = IERC20(ime).balanceOf(address(this));
            _joe = IERC20(joe).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            
            if (_ime > 0){
                IERC20(ime).safeTransfer(
                    IController(controller).treasury(),
                    _ime
                );
            }  
            if (_joe > 0){
                IERC20(joe).safeTransfer(
                    IController(controller).treasury(),
                    _joe
                );
            }  
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxIme";
    }
}