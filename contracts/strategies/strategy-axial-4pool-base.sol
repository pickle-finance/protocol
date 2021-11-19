// SPDX-License-Identifier: MIT	
pragma solidity ^0.6.7;

import "../lib/erc20.sol";
import "../lib/safe-math.sol";
import "../interfaces/swap.sol";
import "../interfaces/wavax.sol";
import "./strategy-axial-base.sol";

import "hardhat/console.sol";

abstract contract StrategyAxial4PoolBase is StrategyAxialBase {
    address public flashLoan;

    // stablecoins
    address public pair1;
    address public pair2;
    address public pair3;
    address public pair4;

    constructor(
        address _flashLoan,
        address _pair1, 
        address _pair2,
        address _pair3,
        address _pair4, 
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAxialBase(
            _poolId,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        flashLoan = _flashLoan;
        pair1 = _pair1;
        pair2 = _pair2;
        pair3 = _pair3;
        pair4 = _pair4; 
    }


    // **** Views ****

    function getMostPremium() public override view returns (address){
        uint256[] memory balances = new uint256[](4);
        balances[0] = ISwap(flashLoan).getTokenBalance(0); 
        balances[1] = ISwap(flashLoan).getTokenBalance(1); 
        balances[2] = ISwap(flashLoan).getTokenBalance(2); 
        balances[3] = ISwap(flashLoan).getTokenBalance(3);  

      
        if (
            balances[0] < balances[1] &&
            balances[0] < balances[2] &&
            balances[0] < balances[3] && pair1 != 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB
        ) {
            return (pair1);
        }else if (
            balances[0] < balances[1] &&
            balances[0] < balances[2] &&
            balances[0] < balances[3] && pair1 == 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB
        ){
            return (pair2);
        }

        if (
            balances[1] < balances[0] &&
            balances[1] < balances[2] &&
            balances[1] < balances[3] 
        ) {
            return (pair2);
        }

        if (
            balances[2] < balances[0] &&
            balances[2] < balances[1] &&
            balances[2] < balances[3] 
        ) {
            return (pair3);
        } 

        if (
            balances[3] < balances[0] &&
            balances[3] < balances[1] &&
            balances[3] < balances[2] 
        ) {
            return (pair4);
        } 

        // If they're somehow equal, we just want one 
        return (pair3);
    }


    // **** State Mutations ****

    function harvest() public onlyBenevolent override {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to) = getMostPremium();

         // Collects Axial  tokens 
        IMasterChefAxialV2(masterChefAxialV3).deposit(poolId, 0);
        uint256 _axial = IERC20(axial).balanceOf(address(this));
        if (_axial > 0) {
            // 10% is sent back to the rewards holder
            uint256 _keep = _axial.mul(keep).div(keepMax);
            uint256 _amount = _axial.sub(_keep);
            if (_keep > 0) {
                _takeFeeAxialToSnob(_keep);
            }

            // if the stablecoin we need is frax, then swap with pangolin
            if( to == 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64){
                IERC20(axial).safeApprove(pangolinRouter, 0);
                IERC20(axial).safeApprove(pangolinRouter, _amount);

                _swapPangolin(axial, to, _amount);

            }else{
                IERC20(axial).safeApprove(joeRouter, 0);
                IERC20(axial).safeApprove(joeRouter, _amount);
                
                _swapTraderJoe(axial, to, _amount); 
            }
        }

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;            //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep2 = _wavax.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeWavaxToSnob(_keep2);
            }
            //convert Avax Rewards
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax.sub(_keep2));   
            _swapTraderJoe(wavax, to, _wavax.sub(_keep2));
        }


        // Adds liquidity to axial's as4d or ac4d pool
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(flashLoan, 0);
            IERC20(to).safeApprove(flashLoan, _to);
            uint256[] memory liquidity = new uint256[](4);

            liquidity[0] = IERC20(pair1).balanceOf(address(this));
            liquidity[1] = IERC20(pair2).balanceOf(address(this));
            liquidity[2] = IERC20(pair3).balanceOf(address(this));
            liquidity[3] = IERC20(pair4).balanceOf(address(this));

            ISwap(flashLoan).addLiquidity(liquidity, 0, now + 60);
        }

        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }
}