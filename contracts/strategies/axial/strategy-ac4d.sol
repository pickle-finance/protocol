// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-4pool-base.sol";

contract StrategyAxialAC4DLp is StrategyAxial4PoolBase {
    // stablecoins
    address public tsd = 0x4fbf0429599460D327BD5F55625E30E4fC066095;
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public frax = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64; 
    address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    uint256 public ac4d_poolId = 1; 
    address public lp = 0x4da067E13974A4d32D342d86fBBbE4fb0f95f382;
    address public swapLoan = 0x8c3c1C6F971C01481150CA7942bD2bbB9Bc27bC7;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyAxial4PoolBase(
        swapLoan, 
        tsd,
        mim,
        frax,
        daiE, 
        ac4d_poolId,
        lp,
        _governance,
        _strategist,
        _controller,
        _timelock

    ){}

    // **** State Mutations ****

    function harvest() public onlyBenevolent override {
        // stablecoin we want to convert to
        (address to) = getMostPremium();

        // Collects AXIAL, TEDDY, and FXS tokens 
        IMasterChefAxialV2(masterChefAxialV3).deposit(poolId, 0);
        uint256 _axial = IERC20(axial).balanceOf(address(this));
        if (_axial > 0) {
            // 10% is sent back to the rewards holder
            uint256 _keep = _axial.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeAxialToSnob(_keep);
            }

            _axial = IERC20(axial).balanceOf(address(this));

            // if the stablecoin we need is frax, then swap with pangolin
            if( to == 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64){
                IERC20(axial).safeApprove(pangolinRouter, 0);
                IERC20(axial).safeApprove(pangolinRouter, _axial);

                _swapPangolin(axial, to, _axial);

            }else{
                IERC20(axial).safeApprove(joeRouter, 0);
                IERC20(axial).safeApprove(joeRouter, _axial);
                
                _swapTraderJoe(axial, to, _axial); 
            }
        }

        uint256 _teddy = IERC20(teddy).balanceOf(address(this));
        if (_teddy > 0) {
            // 10% is sent back to the rewards holder
            uint256 _keep = _teddy.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeTeddyToSnob(_keep);
            }

            _teddy = IERC20(teddy).balanceOf(address(this));

            // if the stablecoin we need is frax, then swap with pangolin
            if( to == 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64){
                IERC20(teddy).safeApprove(pangolinRouter, 0);
                IERC20(teddy).safeApprove(pangolinRouter, _teddy);

                _swapPangolin(teddy, to, _teddy);

            }else{
                IERC20(teddy).safeApprove(joeRouter, 0);
                IERC20(teddy).safeApprove(joeRouter, _teddy);
                
                _swapTraderJoe(teddy, to, _teddy); 
            }
        }

        uint256 _fxs = IERC20(fxs).balanceOf(address(this));
        if (_fxs > 0) {
            // 10% is sent back to the rewards holder
            uint256 _keep = _fxs.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeFxsToSnob(_keep);
            }

            _fxs = IERC20(fxs).balanceOf(address(this));

            IERC20(fxs).safeApprove(pangolinRouter, 0);
            IERC20(fxs).safeApprove(pangolinRouter, _fxs);

            _swapPangolin(fxs, to, _fxs);
        }

        // Take Avax Rewards    
        uint256 _avax = address(this).balance;           //get balance of native Avax
        if (_avax > 0) {                                 //wrap avax into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeWavaxToSnob(_keep2);
            }

            _wavax = IERC20(wavax).balanceOf(address(this));

            //convert Avax Rewards
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);   
            _swapTraderJoe(wavax, to, _wavax);
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

        // Donates DUST
        _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0){
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                _wavax
            );
        }
        _axial = IERC20(axial).balanceOf(address(this));
        if (_axial > 0){
            IERC20(craft).safeTransfer(
                IController(controller).treasury(),
                _axial
            );
        }
        _teddy = IERC20(teddy).balanceOf(address(this));
        if (_teddy > 0){
            IERC20(craft).safeTransfer(
                IController(controller).treasury(),
                _teddy
            );
        }  
        _fxs = IERC20(fxs).balanceOf(address(this));
        if (_fxs > 0){
            IERC20(craft).safeTransfer(
                IController(controller).treasury(),
                _fxs
            );
        }  

        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAC4DLp";
    }
}