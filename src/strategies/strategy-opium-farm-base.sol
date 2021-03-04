// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyOpiumFarmBase is StrategyStakingRewardsBase {
    // Token addresses
    address public opium = 0x888888888889C00c67689029D7856AAC1065eC11;

    // WETH/<token1> pair
    address public token1;

    // How much Opium tokens to keep?
    uint256 public keepOpium = 0;
    uint256 public constant keepOpiumMax = 10000;

    constructor(
        address _token1,
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;
    }

    // **** Setters ****

    function setKeepOpium(uint256 _keepOpium) external {
        require(msg.sender == timelock, "!timelock");
        keepOpium = _keepOpium;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects opium tokens
        IStakingRewards(rewards).getReward();
        uint256 _opium = IERC20(opium).balanceOf(address(this));
        if (_opium > 0) {
            // 10% is locked up for future gov
            uint256 _keepOpium = _opium.mul(keepOpium).div(keepOpiumMax);
            IERC20(opium).safeTransfer(
                IController(controller).treasury(),
                _keepOpium
            );
            uint256 _amount = _opium.sub(_keepOpium);

            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _amount);

            _swapSushiswap(opium, weth, _amount);
        }

        // Swap half ETH for Opium
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);
            _swapSushiswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for WETH/Token
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(
                token1,
                weth,
                _token1,
                _weth,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates weth
            IERC20(weth).safeTransfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back Opium LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
