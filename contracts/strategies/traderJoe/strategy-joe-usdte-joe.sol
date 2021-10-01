// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdteJoeLp is StrategyJoeFarmBase {

    uint256 public avax_joe_poolId = 30;
    address public joe_usdte_joe_lp = 0x1643de2efB8e35374D796297a9f95f64C082a8ce;
	address public usdte = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_joe_poolId,
            joe_usdte_joe_lp,
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
            _takeFeeJoeToSnob(_keep);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _amount);

            _swapTraderJoe(joe, usdte, _amount);
        }

        // Adds in liquidity for PNG/JOE
        uint256 _usdte = IERC20(usdte).balanceOf(address(this));

        _joe = IERC20(joe).balanceOf(address(this));

        if (_usdte > 0 && _joe > 0) {
            IERC20(usdte).safeApprove(joeRouter, 0);
            IERC20(usdte).safeApprove(joeRouter, _usdte);

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);

            IJoeRouter(joeRouter).addLiquidity(
                usdte,
                joe,
                _usdte,
                _joe,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdte).transfer(
                IController(controller).treasury(),
                IERC20(usdte).balanceOf(address(this))
            );
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                IERC20(joe).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeUsdteJoeLp";
    }
}
