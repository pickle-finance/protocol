// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-4pool-base.sol";

contract StrategyAxialAS4DLp is StrategyAxial4PoolBase {
    // stablecoins
    address public tusd = 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB;
    address public usdcE = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address public usdtE = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    uint256 public as4d_poolId = 0; 
    address public lp = 0x3A7387f8BA3ebFFa4A0ECcB1733e940CE2275D3f;
    address public swapLoan = 0x2a716c4933A20Cd8B9f9D9C39Ae7196A85c24228;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyAxial4PoolBase(
        swapLoan,
        tusd, 
        usdcE,
        daiE,
        usdtE, 
        as4d_poolId,
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

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAS4DLp";
    }
}