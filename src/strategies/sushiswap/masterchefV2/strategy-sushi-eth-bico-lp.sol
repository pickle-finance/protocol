// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiEthBicoLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_eth_bico_poolId = 35;

    address public sushi_eth_bico_lp =
        0x55D8EC728eA72477C6Db12cA497a803C8DB361E9;
    address public bico = 0xF17e65822b568B3903685a7c9F496CF7656Cc6C2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_eth_bico_poolId,
            sushi_eth_bico_lp,
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

        // Collects Sushi and BICO tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _bico = IERC20(bico).balanceOf(address(this));
        if (_bico > 0) {
            uint256 _amount = _bico.div(2);
            IERC20(bico).safeApprove(sushiRouter, 0);
            IERC20(bico).safeApprove(sushiRouter, _amount);
            _swapSushiswap(bico, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, bico, _amount);
        }

        // Adds in liquidity for WETH/BICO
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _bico = IERC20(bico).balanceOf(address(this));

        if (_weth > 0 && _bico > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(bico).safeApprove(sushiRouter, 0);
            IERC20(bico).safeApprove(sushiRouter, _bico);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                bico,
                _weth,
                _bico,
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
            IERC20(bico).safeTransfer(
                IController(controller).treasury(),
                IERC20(bico).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthBicoLp";
    }
}
