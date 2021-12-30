// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-masterchefv2-base.sol";

contract StrategySushiNearEthLp is StrategyMasterchefV2FarmBase {
    uint256 public sushi_near_eth_poolId = 13;

    address public sushi_near_eth_lp =
        0x6469B34a2a4723163C4902dbBdEa728D20693C12;
    address public near = 0x85F17Cf997934a597031b2E18a9aB6ebD4B9f6a4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyMasterchefV2FarmBase(
            sushi_near_eth_poolId,
            sushi_near_eth_lp,
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

        // Collects Sushi and NEAR tokens
        IMasterchefV2(masterChef).harvest(poolId, address(this));

        uint256 _near = IERC20(near).balanceOf(address(this));
        if (_near > 0) {
            uint256 _amount = _near.div(2);
            IERC20(near).safeApprove(sushiRouter, 0);
            IERC20(near).safeApprove(sushiRouter, _amount);
            _swapSushiswap(near, weth, _amount);
        }

        uint256 _sushi = IERC20(sushi).balanceOf(address(this));
        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, near, _amount);
        }

        // Adds in liquidity for NEAR/WETH
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _near = IERC20(near).balanceOf(address(this));

        if (_weth > 0 && _near > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(near).safeApprove(sushiRouter, 0);
            IERC20(near).safeApprove(sushiRouter, _near);

            UniswapRouterV2(sushiRouter).addLiquidity(
                near,
                weth,
                _near,
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
            IERC20(near).safeTransfer(
                IController(controller).treasury(),
                IERC20(near).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiNearEthLp";
    }
}
