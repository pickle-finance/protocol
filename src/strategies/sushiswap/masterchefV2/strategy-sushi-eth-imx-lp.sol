// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiEthImxLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_eth_imx_poolId = 27;

    address public sushi_eth_imx_lp =
        0x18Cd890F4e23422DC4aa8C2D6E0Bd3F3bD8873d8;
    address public imx = 0xF57e7e7C23978C3cAEC3C3548E3D615c346e79fF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_eth_imx_poolId,
            sushi_eth_imx_lp,
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

        uint256 _imx = IERC20(imx).balanceOf(address(this));
        if (_imx > 0) {
            uint256 _amount = _imx.div(2);
            IERC20(imx).safeApprove(sushiRouter, 0);
            IERC20(imx).safeApprove(sushiRouter, _amount);
            _swapSushiswap(imx, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, imx, _amount);
        }

        // Adds in liquidity for WETH/IMX
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _imx = IERC20(imx).balanceOf(address(this));

        if (_weth > 0 && _imx > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(imx).safeApprove(sushiRouter, 0);
            IERC20(imx).safeApprove(sushiRouter, _imx);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                imx,
                _weth,
                _imx,
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
            IERC20(imx).safeTransfer(
                IController(controller).treasury(),
                IERC20(imx).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthImxLp";
    }
}
