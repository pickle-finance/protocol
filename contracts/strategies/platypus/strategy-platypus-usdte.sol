// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-platypus-farm-base.sol";

contract StrategyPlatypusUsdtE is StrategyPlatypusFarmBase {
    // stablecoins
    address public usdte = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

  
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

    function _swapPlatypusToWant(uint256 _amount) internal {
        address[] memory path = new address[](3);
        path[0] = platypus;
        path[1] = wavax;
        path[2] = usdte;
        IERC20(platypus).safeApprove(joeRouter, 0);
        IERC20(platypus).safeApprove(joeRouter, _amount);

        _swapTraderJoeWithPath(path, _amount);
    }

    // **** State Mutations ****

    function harvest() public onlyBenevolent override {
        // Collects Platypus  tokens 
        IMasterChefPlatypus(masterChefPlatypus).deposit(poolId, 0);
        uint256 _platypus = IERC20(platypus).balanceOf(address(this));
        if (_platypus > 0) {
            // 10% is sent back to the rewards holder
            uint256 _keep = _platypus.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePlatypusToSnob(_keep);
            }
            //reset amount to latest balance
            _platypus = IERC20(platypus).balanceOf(address(this));

            //swap with path
            _swapPlatypusToWant(_platypus);

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
            _swapTraderJoe(wavax, usdte, _wavax);
        }

        // Adds liquidity to Platypus
        uint256 _usdte = IERC20(usdte).balanceOf(address(this));
        if (_usdte > 0){
            IERC20(usdte).safeApprove(platypusRouter, 0); 
            IERC20(usdte).safeApprove(platypusRouter, _usdte);  

            IPlatypusPools(platypusRouter).deposit(
                usdte, 
                _usdte, 
                address(this), 
                block.timestamp + 120
            );
        }

        // Donates DUST
        _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0){
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                _wavax
            );
        }

        _platypus = IERC20(platypus).balanceOf(address(this));
        if (_platypus > 0){
            IERC20(platypus).transfer(
                IController(controller).treasury(),
                _platypus
            );
        }
       
        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }

    function getName() external override pure returns (string memory) {
        return "StrategyPlatypusUsdtE";
    }
}