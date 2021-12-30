// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiMars4EthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_mars4_eth_poolId = 21;

    address public sushi_mars4_eth_lp =
        0xb50580b0D81D9Fe860746387cEF9a8fc36d48d49;
    address public mars4 = 0x16CDA4028e9E872a38AcB903176719299beAed87;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_mars4_eth_poolId,
            sushi_mars4_eth_lp,
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

        // Collects Sushi and MARS4 tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _mars4 = IERC20(mars4).balanceOf(address(this));
        if (_mars4 > 0) {
            uint256 _amount = _mars4.div(2);
            IERC20(mars4).safeApprove(sushiRouter, 0);
            IERC20(mars4).safeApprove(sushiRouter, _amount);
            _swapSushiswap(mars4, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, mars4, _amount);
        }

        // Adds in liquidity for MARS4/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _mars4 = IERC20(mars4).balanceOf(address(this));

        if (_weth > 0 && _mars4 > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(mars4).safeApprove(sushiRouter, 0);
            IERC20(mars4).safeApprove(sushiRouter, _mars4);

            UniswapRouterV2(sushiRouter).addLiquidity(
                mars4,
                weth,
                _mars4,
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
            IERC20(mars4).safeTransfer(
                IController(controller).treasury(),
                IERC20(mars4).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiMars4EthLp";
    }
}
