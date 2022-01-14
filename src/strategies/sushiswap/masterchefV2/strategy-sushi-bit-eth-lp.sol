// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiBitEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_bit_eth_poolId = 17;

    address public sushi_bit_eth_lp =
        0xE12af1218b4e9272e9628D7c7Dc6354D137D024e;
    address public bit = 0x1A4b46696b2bB4794Eb3D4c26f1c55F9170fa4C5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_bit_eth_poolId,
            sushi_bit_eth_lp,
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

    function getName() external pure override returns (string memory) {
        return "StrategySushiBitEthLp";
    }
}
