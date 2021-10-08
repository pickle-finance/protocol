// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdtEEthELp is StrategyJoeFarmBase {

    uint256 public avax_joe_poolId = 33;

    address public joe_usdt_eth_lp = 0xbe1b87f47fDE3F338Aa3AA98b85435e1709dFD06;
    address public usdt = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public eth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_joe_poolId,
            joe_usdt_eth_lp,
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

            _swapTraderJoe(joe, usdt, _amount);
            _swapTraderJoe(joe, eth, _amount);
        }

        // Adds in liquidity for USDT.e/ETH.e
        uint256 _usdt = IERC20(usdt).balanceOf(address(this));
        uint256 _eth = IERC20(eth).balanceOf(address(this));

        if (_usdt > 0 && _joe > 0) {
            IERC20(usdt).safeApprove(joeRouter, 0);
            IERC20(usdt).safeApprove(joeRouter, _usdt);

            IERC20(eth).safeApprove(joeRouter, 0);
            IERC20(eth).safeApprove(joeRouter, _eth);

            IJoeRouter(joeRouter).addLiquidity(
                usdt,
                eth,
                _usdt,
                _eth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdt).transfer(
                IController(controller).treasury(),
                IERC20(usdt).balanceOf(address(this))
            );
            IERC20(eth).safeTransfer(
                IController(controller).treasury(),
                IERC20(eth).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyJoeUsdtEEthELp";
    }
}
