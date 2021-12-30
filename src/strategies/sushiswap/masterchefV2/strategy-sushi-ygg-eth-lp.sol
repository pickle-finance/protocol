// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiYggEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_ygg_eth_poolId = 6;

    address public sushi_ygg_eth_lp =
        0x99B42F2B49C395D2a77D973f6009aBb5d67dA343;
    address public ygg = 0x25f8087EAD173b73D6e8B84329989A8eEA16CF73;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_ygg_eth_poolId,
            sushi_ygg_eth_lp,
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

        // Collects Sushi and YGG tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _ygg = IERC20(ygg).balanceOf(address(this));
        if (_ygg > 0) {
            uint256 _amount = _ygg.div(2);
            IERC20(ygg).safeApprove(sushiRouter, 0);
            IERC20(ygg).safeApprove(sushiRouter, _amount);
            _swapSushiswap(ygg, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, ygg, _amount);
        }

        // Adds in liquidity for YGG/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _ygg = IERC20(ygg).balanceOf(address(this));

        if (_weth > 0 && _ygg > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(ygg).safeApprove(sushiRouter, 0);
            IERC20(ygg).safeApprove(sushiRouter, _ygg);

            UniswapRouterV2(sushiRouter).addLiquidity(
                ygg,
                weth,
                _ygg,
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
            IERC20(ygg).safeTransfer(
                IController(controller).treasury(),
                IERC20(ygg).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiYggEthLp";
    }
}
