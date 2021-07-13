// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";
import "../../../interfaces/iron.sol";

contract StrategyIronIS3USD is StrategyBase {
    // Token addresses
    address public ice = 0x4A81f8796e0c6Ad4877A51C86693B0dE8093F2ef;
    address public ironchef = 0x1fD1259Fa8CdC60c6E8C86cfA592CA1b8403DFaD;
    address public is3usd = 0xb4d09ff3da7f9e9a2ba029cb0a81a989fd7b8f17;
    address public ironSwap = 0x837503e8A8753ae17fB8C8151B8e6f586defCb57;
    uint256 public poolId = 0;
    address public dfynRouter = 0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429;

    // Stablecoin addresses
    address public dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(is3usd, _governance, _strategist, _controller, _timelock)
    {}

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?

        // Collects ICE tokens
        IIronchef(ironchef).withdraw(poolId, 0, address(this));
        uint256 _rewardBalance = IERC20(ice).balanceOf(address(this));
        if (_rewardBalance == 0) {
            return;
        }

        IERC20(ice).safeApprove(dfynRouter, 0);
        IERC20(ice).safeApprove(dfynRouter, _rewardBalance);

        UniswapRouterV2(dfynRouter).swapExactTokensForTokens(
            _rewardBalance,
            1,
            [ice, usdc, dai],
            address(this),
            now.add(60)
        );

        // Adds liquidity to Iron's 3pool
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            IERC20(dai).safeApprove(ironSwap, 0);
            IERC20(dai).safeApprove(ironSwap, _dai);
            uint256[3] memory liquidity;
            liquidity[2] = _dai;
            IIronSwap(ironSwap).add_liquidity(liquidity, 1, now.add(60));
        }

        _distributePerformanceFeesAndDeposit();
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IIronchef(ironchef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view virtual returns (uint256) {
        uint256 _pendingReward = IIronchef(ironchef).pendingReward(
            poolId,
            address(this)
        );
        return _pendingReward;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(ironchef, 0);
            IERC20(want).safeApprove(ironchef, _want);
            IIronchef(ironchef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IIronchef(ironchef).withdraw(poolId, _amount, address(this));
        return _amount;
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyIronIS3USD";
    }
}
