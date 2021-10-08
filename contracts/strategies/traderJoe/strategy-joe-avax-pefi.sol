// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxPefiLp is StrategyJoeFarmBase {

    uint256 public avax_pefi_poolId = 9;

    address public joe_avax_pefi_lp = 0xb78c8238bD907c42BE45AeBdB4A8C8a5D7B49755;
    address public pefi = 0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_pefi_poolId,
            joe_avax_pefi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Joe tokens
        IMasterChefJoeV2(masterChefJoeV2).deposit(poolId, 0);

        uint256 _joe = IERC20(joe).balanceOf(address(this));
        if (_joe > 0) {
            // 10% is sent to treasury
            uint256 _keep = _joe.mul(keep).div(keepMax);
            uint256 _amount = _joe.sub(_keep).div(2);
            if (_keep > 0) {
                _takeFeeJoeToSnob(_keep);
            }
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keep));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, pefi, _amount);
        }

        // Adds in liquidity for AVAX/PEFI
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _pefi = IERC20(pefi).balanceOf(address(this));

        if (_wavax > 0 && _pefi > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(pefi).safeApprove(joeRouter, 0);
            IERC20(pefi).safeApprove(joeRouter, _pefi);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                pefi,
                _wavax,
                _pefi,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wavax).transfer(
                IController(controller).treasury(),
                IERC20(wavax).balanceOf(address(this))
            );
            IERC20(pefi).safeTransfer(
                IController(controller).treasury(),
                IERC20(pefi).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxPefiLp";
    }
}
