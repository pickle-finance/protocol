// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxMyakLp is StrategyJoeFarmBase {
    uint256 public avax_myak_poolId = 51;

    address public joe_avax_myak_lp =
        0xAD3Afde5B6b8C353078Fd368f508C97d593353cc;
    address public myak = 0xdDAaAD7366B455AfF8E7c82940C43CEB5829B604;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_myak_poolId,
            joe_avax_myak_lp,
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
            uint256 _keepJOE = _joe.mul(keepJOE).div(keepJOEMax);
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _keepJOE
            );
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keepJOE));

            _swapTraderJoe(joe, wavax, _amount);
            _swapTraderJoe(joe, myak, _amount);
        }

        // Adds in liquidity for AVAX/MYAK
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _myak = IERC20(myak).balanceOf(address(this));

        if (_wavax > 0 && _myak > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(myak).safeApprove(joeRouter, 0);
            IERC20(myak).safeApprove(joeRouter, _myak);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                myak,
                _wavax,
                _myak,
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
            IERC20(myak).safeTransfer(
                IController(controller).treasury(),
                IERC20(myak).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxMyakLp";
    }
}
