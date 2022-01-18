// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-platypus-farm-base.sol";

contract StrategyPlatypusUsdcE is StrategyPlatypusFarmBase {
    // stablecoins
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

  
    uint256 public _poolId = 1; 
    address public lp = 0x909B0ce4FaC1A0dCa78F8Ca7430bBAfeEcA12871;
    
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
        path[2] = usdce;

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
            _swapTraderJoe(wavax, usdce, _wavax);
        }


        // Adds liquidity to Platypus
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));
        IERC20(usdce).safeApprove(platypusRouter, _usdce);  
        IPlatypusPools(platypusRouter).deposit(usdce, _usdce, address(this), block.timestamp + 120);
       

        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }

    function getName() external override pure returns (string memory) {
        return "StrategyPlatypusUsdce";
    }
}