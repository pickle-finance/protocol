// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiEthPspLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_eth_psp_poolId = 31;

    address public sushi_eth_psp_lp =
        0x458ae80894A0924Ac763C034977e330c565F1687;
    address public psp = 0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_eth_psp_poolId,
            sushi_eth_psp_lp,
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

        // Collects Sushi and PSP tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _psp = IERC20(psp).balanceOf(address(this));
        if (_psp > 0) {
            uint256 _amount = _psp.div(2);
            IERC20(psp).safeApprove(sushiRouter, 0);
            IERC20(psp).safeApprove(sushiRouter, _amount);
            _swapSushiswap(psp, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, psp, _amount);
        }

        // Adds in liquidity for WETH/PSP
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _psp = IERC20(psp).balanceOf(address(this));

        if (_weth > 0 && _psp > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(psp).safeApprove(sushiRouter, 0);
            IERC20(psp).safeApprove(sushiRouter, _psp);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                psp,
                _weth,
                _psp,
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
            IERC20(psp).safeTransfer(
                IController(controller).treasury(),
                IERC20(psp).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthPspLp";
    }
}
