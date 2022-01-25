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
            balances[0] < balances[3] && 
            pair1 != 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB
        ) {
            return (pair1);
        }else if (
            balances[0] < balances[1] &&
            balances[0] < balances[2] &&
            balances[0] < balances[3] && 
            pair1 == 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB
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
}