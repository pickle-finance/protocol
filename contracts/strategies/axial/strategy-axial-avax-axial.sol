// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-axial-farm-base.sol";

contract StrategyAxialAvaxAxialLp is StrategyAxialFarmBase {

    uint256 public avax_axial_poolId = 2;

    address public joe_avax_axial_lp = 0x5305A6c4DA88391F4A9045bF2ED57F4BF0cF4f62;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAxialFarmBase(
            avax_axial_poolId,
            joe_avax_axial_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {

        // Collects Axial  tokens 
        IMasterChefAxialV2(masterChefAxialV3).deposit(poolId, 0);

        uint256 _axial = IERC20(axial).balanceOf(address(this));
        if (_axial > 0) {
            // 10% is sent to treasury
            uint256 _keep = _axial.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeAxialToSnob(_keep);
            }

            _axial = IERC20(axial).balanceOf(address(this));

            IERC20(axial).safeApprove(joeRouter, 0);
            IERC20(axial).safeApprove(joeRouter, _axial);

            _swapTraderJoe(axial, wavax, _axial.div(2));    
        }

        // Adds in liquidity for AVAX/Axial
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        _axial = IERC20(axial).balanceOf(address(this));

        if (_wavax > 0 && _axial > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(snob).safeApprove(joeRouter, 0);
            IERC20(snob).safeApprove(joeRouter, _axial);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                axial,
                _wavax,
                _axial,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));

            if(_wavax>0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax);
            }

            _axial = IERC20(axial).balanceOf(address(this));
            if(_axial>0){
                IERC20(axial).safeTransfer(
                    IController(controller).treasury(),
                    _axial);
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyAxialAvaxAxialLp";
    }
}