// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-3pool-base.sol";

contract StrategyAxialAM3DLp is StrategyAxial3PoolBase {
    // stablecoins
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public usdcE = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public daiE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    uint256 public am3d_poolId = 3; 
    address public lp = 0xc161E4B11FaF62584EFCD2100cCB461A2DdE64D1;
    address public swapLoan = 0x90c7b96AD2142166D001B27b5fbc128494CDfBc8;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public 
    StrategyAxial3PoolBase(
        swapLoan,
        mim,
        usdcE,
        daiE, 
        am3d_poolId,
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

         // Collects Axial  tokens 
        IMasterChefAxialV2(masterChefAxialV3).deposit(poolId, 0);
        uint256 _axial = IERC20(axial).balanceOf(address(this));
        if (_axial > 0) {
            // x% is sent back to the rewards holder
            // to be used to lock up in as veCRV in a future date
            uint256 _keep = _axial.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeAxialToSnob(_keep);
            }

            _axial = IERC20(axial).balanceOf(address(this));

            IERC20(axial).safeApprove(joeRouter, 0);
            IERC20(axial).safeApprove(joeRouter, _axial);
            _swapTraderJoe(axial, to, _axial);
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
                _takeFeeWavaxToSnob(_keep);
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
            uint256[] memory liquidity = new uint256[](3);

            liquidity[0] = IERC20(pair1).balanceOf(address(this));
            liquidity[1] = IERC20(pair2).balanceOf(address(this));
            liquidity[2] = IERC20(pair3).balanceOf(address(this));

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
            IERC20(axial).safeTransfer(
                IController(controller).treasury(),
                _axial
            );
        }

        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAM3DLp";
    }
}