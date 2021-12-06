// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-3pool-base.sol";

contract StrategyAxialAA3DLp is StrategyAxial3PoolBase {
    // stablecoins
    address public avai = 0x346A59146b9b4a77100D369a3d18E8007A9F46a6;
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public usdcE = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    uint256 public am3d_poolId = 4; 
    address public lp = 0xaD556e7dc377d9089C6564f9E8d275f5EE4da22d;
    address public swapLoan = 0x6EfbC734D91b229BE29137cf9fE531C1D3bf4Da6;
    
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
        avai, 
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

        uint256 _orca = IERC20(orca).balanceOf(address(this));
        if (_orca > 0) {
            // x% is sent back to the rewards holder
            // to be used to lock up in as veCRV in a future date
            uint256 _keep = _orca.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeOrcaToSnob(_keep);
            }

            _orca = IERC20(orca).balanceOf(address(this));

            IERC20(orca).safeApprove(joeRouter, 0);
            IERC20(orca).safeApprove(joeRouter, _orca);

            _swapTraderJoe(orca, to, _orca);
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
        _orca = IERC20(orca).balanceOf(address(this));
        if (_orca > 0){
            IERC20(orca).safeTransfer(
                IController(controller).treasury(),
                _orca
            );
        }

        // We want to get back sCRV
        _distributePerformanceFeesAndDeposit();
    }

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAA3DLp";
    }
}