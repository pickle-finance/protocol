// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-platypus-farm-base.sol";

contract StrategyPlatypusDaiE is StrategyPlatypusFarmBase {
    // stablecoins
      address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    
  // UPDATE POOLID
    uint256 public _poolId = 0; 
    address public lp = 0x0D26D103c91F63052Fbca88aAF01d5304Ae40015;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyPlatypusFarmBase(
        _poolId,
        lp,
        _governance,
        _strategist,
        _controller,
        _timelock

    ){}

    // **** State Mutations ****

    function harvest() public onlyBenevolent override {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to

         // Collects Platypus  tokens 
        IMasterChefPlatypus(masterChefPlatypus).deposit(poolId, 0);
        uint256 _platypus = IERC20(platypus).balanceOf(address(this));
        if (_platypus > 0) {
            // 10% is sent back to the rewards holder
            uint256 _keep = _platypus.mul(keep).div(keepMax);
            uint256 _amount = _platypus.sub(_keep);
            if (_keep > 0) {
                _takeFeePlatypusToSnob(_keep);
            }
        //reset amount to latest balance
        _amount = IERC20(platypus).balanceOf(address(this));

        //approve the balance for swapping
        IERC20(platypus).safeApprove(joeRouter, 0);
        IERC20(platypus).safeApprove(joeRouter, _amount);

        //create a path for the swap
        address[] memory path = new address[](3);
        path[0] = platypus;
        path[1] = wavax;
        path[2] = daiE;

        //swap with path
        _swapTraderJoeWithPath(path, _amount);

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
        //update balance
        _wavax = IERC20(wavax).balanceOf(address(this));

            //convert Avax Rewards
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);   
            _swapTraderJoe(wavax, daiE, _wavax);
        }


        // Adds liquidity to Platypus
        uint256 _daiE = IERC20(daiE).balanceOf(address(this));
        IPlatypusPools(platypusRouter).deposit(daiE, _daiE, address(this), block.timestamp + 120);
       

        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }

    function getName() external override pure returns (string memory) {
        return "StrategyPlatypusDaiE";
    }
}