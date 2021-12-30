// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiEthVegaLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_eth_vega_poolId = 39;

    address public sushi_eth_vega_lp =
        0x29C827Ce49aCCF68A1a278C67C9D30c52fBbC348;
    address public vega = 0xcB84d72e61e383767C4DFEb2d8ff7f4FB89abc6e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_eth_vega_poolId,
            sushi_eth_vega_lp,
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

        // Collects Sushi and VEGA tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _vega = IERC20(vega).balanceOf(address(this));
        if (_vega > 0) {
            uint256 _amount = _vega.div(2);
            IERC20(vega).safeApprove(sushiRouter, 0);
            IERC20(vega).safeApprove(sushiRouter, _amount);
            _swapSushiswap(vega, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, vega, _amount);
        }

        // Adds in liquidity for WETH/VEGA
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _vega = IERC20(vega).balanceOf(address(this));

        if (_weth > 0 && _vega > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(vega).safeApprove(sushiRouter, 0);
            IERC20(vega).safeApprove(sushiRouter, _vega);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                vega,
                _weth,
                _vega,
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
            IERC20(vega).safeTransfer(
                IController(controller).treasury(),
                IERC20(vega).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthVegaLp";
    }
}
