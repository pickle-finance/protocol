// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxSherpaLp is StrategyJoeFarmBase {

    uint256 public avax_sherpa_poolId = 23;

    address public joe_avax_sherpa_lp = 0xf0d7EC33147Ec3bEfd24B880472307bF3a01BB8A;
    address public sherpa = 0xa5E59761eBD4436fa4d20E1A27cBa29FB2471Fc6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_sherpa_poolId,
            joe_avax_sherpa_lp,
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
            _swapTraderJoe(joe, sherpa, _amount);
        }

        // Adds in liquidity for AVAX/SHERPA
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _sherpa = IERC20(sherpa).balanceOf(address(this));

        if (_wavax > 0 && _sherpa > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(sherpa).safeApprove(joeRouter, 0);
            IERC20(sherpa).safeApprove(joeRouter, _sherpa);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                sherpa,
                _wavax,
                _sherpa,
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
            IERC20(sherpa).safeTransfer(
                IController(controller).treasury(),
                IERC20(sherpa).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxSherpaLp";
    }
}
