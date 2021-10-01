// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeUsdceEtheLp is StrategyJoeFarmBase {
    uint256 public usdc_eth_poolId = 55;

    address public joe_usdc_eth_lp = 0x199fb78019A08af2Cb6a078409D0C8233Eba8a0c;
    address public usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public eth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            usdc_eth_poolId,
            joe_usdc_eth_lp,
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
            uint256 _keepJOE = _joe.mul(keep).div(keepMax);
            IERC20(joe).safeTransfer(
                IController(controller).treasury(),
                _keepJOE
            );
            uint256 _amount = _joe.sub(_keepJOE).div(2);
            IERC20(joe).safeApprove(joeRouter, 0);
            IERC20(joe).safeApprove(joeRouter, _joe.sub(_keepJOE));

            _swapTraderJoe(joe, usdc, _amount);
            _swapTraderJoe(joe, eth, _amount);
        }

        // Adds in liquidity for USDC/ETH
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));

        uint256 _eth = IERC20(eth).balanceOf(address(this));

        if (_usdc > 0 && _eth > 0) {
            IERC20(usdc).safeApprove(joeRouter, 0);
            IERC20(usdc).safeApprove(joeRouter, _usdc);

            IERC20(eth).safeApprove(joeRouter, 0);
            IERC20(eth).safeApprove(joeRouter, _eth);

            IJoeRouter(joeRouter).addLiquidity(
                usdc,
                eth,
                _usdc,
                _eth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdc).transfer(
                IController(controller).treasury(),
                IERC20(usdc).balanceOf(address(this))
            );
            IERC20(eth).safeTransfer(
                IController(controller).treasury(),
                IERC20(eth).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeUsdceEtheLp";
    }
}
