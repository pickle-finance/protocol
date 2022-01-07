// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/newo-staking-rewards.sol";

abstract contract StrategyNewoFarmBase is StrategyBase {
    // Token addresses
    address public constant stakingRewards =
        0x9D4af0f08B300437b4f0d97A1C5c478F1e0A7D3C;
    address public constant newo = 0x1b890fD37Cd50BeA59346fC2f8ddb7cd9F5Fabd5;

    // USDC/<token1> pair
    address public token1;

    // How much NEWO tokens to keep?
    uint256 public keepNEWO = 0;
    uint256 public constant keepNEWOMax = 10000;

    constructor(
        address _token1,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        token1 = _token1;
    }

    function balanceOfPool() public view override returns (uint256) {
        return INewoStakingRewards(stakingRewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return INewoStakingRewards(stakingRewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingRewards, 0);
            IERC20(want).safeApprove(stakingRewards, _want);
            INewoStakingRewards(stakingRewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        INewoStakingRewards(stakingRewards).withdraw(_amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepNEWO(uint256 _keepNEWO) external {
        require(msg.sender == timelock, "!timelock");
        keepNEWO = _keepNEWO;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects NEWO tokens
        INewoStakingRewards(stakingRewards).getReward();
        uint256 _newo = IERC20(newo).balanceOf(address(this));
        if (_newo > 0) {
            // 10% is locked up for future gov
            uint256 _keepNEWO = _newo.mul(keepNEWO).div(keepNEWOMax);
            IERC20(newo).safeTransfer(
                IController(controller).treasury(),
                _keepNEWO
            );
            uint256 _swap = _newo.sub(_keepNEWO);
            IERC20(newo).safeApprove(univ2Router2, 0);
            IERC20(newo).safeApprove(univ2Router2, _swap);
            _swapUniswap(newo, usdc, _swap);
        }

        // Swap half USDC for token1
        uint256 _usdc = IERC20(usdc).balanceOf(address(this));
        if (_usdc > 0) {
            IERC20(usdc).safeApprove(univ2Router2, 0);
            IERC20(usdc).safeApprove(univ2Router2, _usdc);
            _swapUniswap(usdc, token1, _usdc.div(2));
        }

        // Adds in liquidity for ETH/token1
        _usdc = IERC20(usdc).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_usdc > 0 && _token1 > 0) {
            IERC20(usdc).safeApprove(univ2Router2, 0);
            IERC20(usdc).safeApprove(univ2Router2, _usdc);
            IERC20(token1).safeApprove(univ2Router2, 0);
            IERC20(token1).safeApprove(univ2Router2, _token1);

            UniswapRouterV2(univ2Router2).addLiquidity(
                token1,
                usdc,
                _token1,
                _usdc,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(usdc).transfer(
                IController(controller).treasury(),
                IERC20(usdc).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back NEWO LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
