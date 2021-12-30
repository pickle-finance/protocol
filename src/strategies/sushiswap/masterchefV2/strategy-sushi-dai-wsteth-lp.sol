// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiDaiWstethLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_dai_wsteth_poolId = 15;

    address public sushi_dai_wsteth_lp =
        0xc5578194D457dcce3f272538D1ad52c68d1CE849;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public wsteth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_dai_wsteth_poolId,
            sushi_dai_wsteth_lp,
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

        // Collects Sushi and LIDO tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            uint256 _amount = _dai.div(2);
            IERC20(dai).safeApprove(sushiRouter, 0);
            IERC20(dai).safeApprove(sushiRouter, _amount);
            _swapSushiswap(dai, wsteth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, wsteth, _amount);
            _swapSushiswap(sushi, dai, _amount);
        }

        // Adds in liquidity for DAI/WSTETH
        uint256 _wsteth = IERC20(wsteth).balanceOf(address(this));

        _dai = IERC20(dai).balanceOf(address(this));

        if (_wsteth > 0 && _dai > 0) {
            IERC20(wsteth).safeApprove(sushiRouter, 0);
            IERC20(wsteth).safeApprove(sushiRouter, _wsteth);

            IERC20(dai).safeApprove(sushiRouter, 0);
            IERC20(dai).safeApprove(sushiRouter, _dai);

            UniswapRouterV2(sushiRouter).addLiquidity(
                dai,
                wsteth,
                _dai,
                _wsteth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(wsteth).transfer(
                IController(controller).treasury(),
                IERC20(wsteth).balanceOf(address(this))
            );
            IERC20(dai).safeTransfer(
                IController(controller).treasury(),
                IERC20(dai).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDaiWstethLp";
    }
}
