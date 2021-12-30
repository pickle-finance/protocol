// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiXdefiEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_xdefi_eth_poolId = 28;

    address public sushi_xdefi_eth_lp =
        0x37FC088cFD67349Be00f5504D00ddB7F2274b3f6;
    address public xdefi = 0x72B886d09C117654aB7dA13A14d603001dE0B777;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_xdefi_eth_poolId,
            sushi_xdefi_eth_lp,
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

        // Collects Sushi and XDEFI tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _xdefi = IERC20(xdefi).balanceOf(address(this));
        if (_xdefi > 0) {
            uint256 _amount = _xdefi.div(2);
            IERC20(xdefi).safeApprove(sushiRouter, 0);
            IERC20(xdefi).safeApprove(sushiRouter, _amount);
            _swapSushiswap(xdefi, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, xdefi, _amount);
        }

        // Adds in liquidity for XDEFI/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _xdefi = IERC20(xdefi).balanceOf(address(this));

        if (_weth > 0 && _xdefi > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(xdefi).safeApprove(sushiRouter, 0);
            IERC20(xdefi).safeApprove(sushiRouter, _xdefi);

            UniswapRouterV2(sushiRouter).addLiquidity(
                xdefi,
                weth,
                _xdefi,
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
            IERC20(xdefi).safeTransfer(
                IController(controller).treasury(),
                IERC20(xdefi).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiXdefiEthLp";
    }
}
