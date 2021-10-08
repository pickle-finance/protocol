// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxLinkELp is StrategyJoeFarmBase {

    uint256 public avax_link_poolId = 29;

    address public joe_avax_link_lp = 0x6F3a0C89f611Ef5dC9d96650324ac633D02265D3;
    address public link = 0x5947BB275c521040051D82396192181b413227A3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_link_poolId,
            joe_avax_link_lp,
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
            _swapTraderJoe(joe, link, _amount);
        }

        // Adds in liquidity for AVAX/LINK
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _link = IERC20(link).balanceOf(address(this));

        if (_wavax > 0 && _link > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(link).safeApprove(joeRouter, 0);
            IERC20(link).safeApprove(joeRouter, _link);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                link,
                _wavax,
                _link,
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
            IERC20(link).safeTransfer(
                IController(controller).treasury(),
                IERC20(link).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeAvaxLinkELp";
    }
}
