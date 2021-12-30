// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiRadarEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_radar_eth_poolId = 42;

    address public sushi_radar_eth_lp =
        0x559eBE4E206e6B4D50e9bd3008cDA7ce640C52cb;
    address public radar = 0x44709a920fCcF795fbC57BAA433cc3dd53C44DbE;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_radar_eth_poolId,
            sushi_radar_eth_lp,
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

        // Collects Sushi and RADAR tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _radar = IERC20(radar).balanceOf(address(this));
        if (_radar > 0) {
            uint256 _amount = _radar.div(2);
            IERC20(radar).safeApprove(sushiRouter, 0);
            IERC20(radar).safeApprove(sushiRouter, _amount);
            _swapSushiswap(radar, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, radar, _amount);
        }

        // Adds in liquidity for RADAR/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _radar = IERC20(radar).balanceOf(address(this));

        if (_weth > 0 && _radar > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(radar).safeApprove(sushiRouter, 0);
            IERC20(radar).safeApprove(sushiRouter, _radar);

            UniswapRouterV2(sushiRouter).addLiquidity(
                radar,
                weth,
                _radar,
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
            IERC20(radar).safeTransfer(
                IController(controller).treasury(),
                IERC20(radar).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiRadarEthLp";
    }
}
