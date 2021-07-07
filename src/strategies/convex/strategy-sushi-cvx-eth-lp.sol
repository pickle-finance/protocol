// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiCvxEthLp is StrategyMasterchefV2FarmBase {

    uint256 public sushi_cvx_poolId = 1;

    address public sushi_cvx_eth_lp = 0x05767d9EF41dC40689678fFca0608878fb3dE906;
    address public cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_cvx_poolId,
            sushi_cvx_eth_lp,
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

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            uint256 _amount = _cvx.div(2);
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _amount);
            _swapSushiswap(cvx, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, cvx, _amount);
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

    function getName() external override pure returns (string memory) {
        return "StrategySushiCvxEthLp";
    }
}