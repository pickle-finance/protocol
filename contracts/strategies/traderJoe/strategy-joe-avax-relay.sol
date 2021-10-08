// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-farm-base.sol";

contract StrategyJoeAvaxRelayLp is StrategyJoeFarmBase {
    uint256 public avax_relay_poolId = 59;

    address public joe_avax_relay_lp =
        0x41f3092d6Dd8dB25ec0f7395F56CAc107EcB7A12;
    address public relay = 0x78c42324016cd91D1827924711563fb66E33A83A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeFarmBase(
            avax_relay_poolId,
            joe_avax_relay_lp,
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
            _swapTraderJoe(joe, relay, _amount);
        }

        // Adds in liquidity for AVAX/RELAY
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _relay = IERC20(relay).balanceOf(address(this));

        if (_wavax > 0 && _relay > 0) {
            IERC20(wavax).safeApprove(joeRouter, 0);
            IERC20(wavax).safeApprove(joeRouter, _wavax);

            IERC20(relay).safeApprove(joeRouter, 0);
            IERC20(relay).safeApprove(joeRouter, _relay);

            IJoeRouter(joeRouter).addLiquidity(
                wavax,
                relay,
                _wavax,
                _relay,
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
            IERC20(relay).safeTransfer(
                IController(controller).treasury(),
                IERC20(relay).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJoeAvaxRelayLp";
    }
}
