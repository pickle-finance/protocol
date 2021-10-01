// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeDaiJoeLp is StrategyJoeFarmBase {

    uint256 public avax_joe_poolId = 14;

    address public joe_dai_joe_lp = 0x061F9eDB3858D2Faa5f629f6AE34140C92229Ea8;
    address public dai = 0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_joe_poolId,
            joe_dai_joe_lp,
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
        // i.e. will we be heavily frontrunned?
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

            _swapTraderJoe(joe, dai, _amount);
        }

        // Adds in liquidity for Joe/DAI
        uint256 _dai = IERC20(dai).balanceOf(address(this));

        _joe = IERC20(joe).balanceOf(address(this));

        if (_dai > 0 && _joe > 0) {
            IERC20(dai).safeApprove(joeRouter, 0);
            IERC20(dai).safeApprove(joeRouter, _dai);

            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe);

            IJoeRouter(joeRouter).addLiquidity(
                dai,
                joe,
                _dai,
                _joe,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(dai).transfer(
                IController(controller).treasury(),
                IERC20(dai).balanceOf(address(this))
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
        return "StrategyJoeDaiJoeLp";
    }
}
