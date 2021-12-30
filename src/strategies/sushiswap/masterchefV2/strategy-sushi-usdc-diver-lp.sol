// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiUsdcDiverLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_usdc_diver_poolId = 1;

    address public sushi_usdc_diver_eth_lp =
        0x05767d9EF41dC40689678fFca0608878fb3dE906;
    address public diver = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_usdc_diver_poolId,
            sushi_usdc_diver_eth_lp,
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

        // Collects Sushi and CVX tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _diver = IERC20(diver).balanceOf(address(this));
        if (_diver > 0) {
            uint256 _amount = _diver.div(2);
            IERC20(diver).safeApprove(sushiRouter, 0);
            IERC20(diver).safeApprove(sushiRouter, _amount);
            _swapSushiswap(diver, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, diver, _amount);
        }

        // Adds in liquidity for WETH/CVX
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _cvx = IERC20(cvx).balanceOf(address(this));

        if (_weth > 0 && _cvx > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                cvx,
                _weth,
                _cvx,
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
            IERC20(cvx).safeTransfer(
                IController(controller).treasury(),
                IERC20(cvx).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiUsdcDiverLp";
    }
}
