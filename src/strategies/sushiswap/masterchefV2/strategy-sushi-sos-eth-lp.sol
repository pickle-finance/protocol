// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiSosEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_sos_eth_poolId = 45;

    address public sushi_sos_eth_lp =
        0xB84C45174Bfc6b8F3EaeCBae11deE63114f5c1b2;
    address public sos = 0x3b484b82567a09e2588A13D54D032153f0c0aEe0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_sos_eth_poolId,
            sushi_sos_eth_lp,
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
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and SOS tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _sos = IERC20(sos).balanceOf(address(this));
        if (_sos > 0) {
            uint256 _amount = _sos.div(2);
            IERC20(sos).safeApprove(sushiRouter, 0);
            IERC20(sos).safeApprove(sushiRouter, _amount);
            _swapSushiswap(sos, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, sos, _amount);
        }

        // Adds in liquidity for SOS/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _sos = IERC20(sos).balanceOf(address(this));

        if (_weth > 0 && _sos > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(sos).safeApprove(sushiRouter, 0);
            IERC20(sos).safeApprove(sushiRouter, _sos);

            UniswapRouterV2(sushiRouter).addLiquidity(
                sos,
                weth,
                _sos,
                _weth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(sos).safeTransfer(
                IController(controller).treasury(),
                IERC20(sos).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiSosEthLp";
    }
}
