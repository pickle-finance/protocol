// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";
import "../../interfaces/uniswapv2.sol";

abstract contract StrategyComethFarmBase is StrategyStakingRewardsBase {
    // Token addresses
    address public must = 0x9C78EE466D6Cb57A4d01Fd887D2b5dFb2D46288f;

    // How much MUST tokens to keep?
    uint256 public keepMUST = 0;
    uint256 public constant keepMUSTMax = 10000;

    // Uniswap swap paths
    address token0;
    address token1;
    address[] public must_token0_path;
    address[] public token0_token1_path;

    constructor(
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
        address _token0 = IUniswapV2Pair(_lp).token0();
        address _token1 = IUniswapV2Pair(_lp).token1();

        // weth should be token0, must should be token1
        if (_token1 == weth || _token0 == must) {
            token0 = _token1;
            token1 = _token0;
        } else {
            token0 = _token0;
            token1 = _token1;
        }

        must_token0_path = new address[](2);
        must_token0_path[0] = must;
        must_token0_path[1] = token0;

        token0_token1_path = new address[](2);
        token0_token1_path[0] = token0;
        token0_token1_path[1] = token1;
    }

    // **** Setters ****

    function setKeepMUST(uint256 _keepMUST) external {
        require(msg.sender == timelock, "!timelock");
        keepMUST = _keepMUST;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects MSUT tokens
        IStakingRewards(rewards).getReward();
        uint256 _must = IERC20(must).balanceOf(address(this));

        if (_must > 0) {
            // 10% is locked up for future gov
            uint256 _keepMUST = _must.mul(keepMUST).div(keepMUSTMax);
            if (_keepMUST > 0) {
                IERC20(must).safeTransfer(
                    IController(controller).treasury(),
                    _keepMUST
                );
                _must = _must.sub(_keepMUST);
            }
        }

        if (token1 == must) {
            IERC20(must).safeApprove(univ2Router2, 0);
            IERC20(must).safeApprove(univ2Router2, _must.div(2));
            _swapUniswapWithPath(must_token0_path, _must.div(2));
        } else {
            IERC20(must).safeApprove(univ2Router2, 0);
            IERC20(must).safeApprove(univ2Router2, _must);
            _swapUniswapWithPath(must_token0_path, _must);

            uint256 swapAmount = IERC20(token0).balanceOf(address(this)).div(2);
            IERC20(token0).safeApprove(univ2Router2, 0);
            IERC20(token0).safeApprove(univ2Router2, swapAmount);
            _swapUniswapWithPath(token0_token1_path, swapAmount);
        }

        // Adds in liquidity for ETH/DAI
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(univ2Router2, 0);
            IERC20(token0).safeApprove(univ2Router2, _token0);

            IERC20(token1).safeApprove(univ2Router2, 0);
            IERC20(token1).safeApprove(univ2Router2, _token1);

            UniswapRouterV2(univ2Router2).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back UNI LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
