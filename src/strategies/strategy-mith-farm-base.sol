// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyMithFarmBase is StrategyStakingRewardsBase {
    // Token addresses
    address public mis = 0x4b4D2e899658FB59b1D518b68fe836B100ee8958;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // USDT/<token1> pair
    address public token1;

    // How much MIS tokens to keep?
    uint256 public keepMIS = 0;
    uint256 public constant keepMISMax = 10000;

    // Uniswap swap paths
    address[] public mis_usdt_path;
    address[] public usdt_token1_path;

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

        mis_usdt_path = new address[](2);
        mis_usdt_path[0] = mis;
        mis_usdt_path[1] = usdt;

        usdt_token1_path = new address[](2);
        usdt_token1_path[0] = usdt;
        usdt_token1_path[1] = token1;
    }

    // **** Setters ****

    function setKeepMIS(uint256 _keepMIS) external {
        require(msg.sender == timelock, "!timelock");
        keepMIS = _keepMIS;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.
        address[] memory path = new address[](2);

        // Collects MIS tokens
        IStakingRewards(rewards).getReward();
        uint256 _mis = IERC20(mis).balanceOf(address(this));
        if (_mis > 0) {
            // 10% is locked up for future gov
            uint256 _keepMIS = _mis.mul(keepMIS).div(keepMISMax);
            IERC20(mis).safeTransfer(
                IController(controller).treasury(),
                _keepMIS
            );
            _swapSushiswapWithPath(mis_usdt_path, _mis.sub(_keepMIS));
        }

        // Swap half USDT for token
        uint256 _usdt = IERC20(usdt).balanceOf(address(this));
        if (_usdt > 0) {
            _swapSushiswapWithPath(usdt_token1_path, _usdt.div(2));
        }

        // Adds in liquidity for USDT/Token
        _usdt = IERC20(usdt).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_usdt > 0 && _token1 > 0) {
            IERC20(usdt).safeApprove(sushiRouter, 0);
            IERC20(usdt).safeApprove(sushiRouter, _usdt);

            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(
                usdt,
                token1,
                _usdt,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdt).safeTransfer(
                IController(controller).treasury(),
                IERC20(usdt).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back MIS LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
