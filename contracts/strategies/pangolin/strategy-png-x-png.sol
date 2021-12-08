// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;


import "../strategy-staking-rewards-base.sol";

contract StrategyPngXPngLp is StrategyStakingRewardsBase {
    // Token addresses
    address public stake_png_rewards = 0x88afdaE1a9F58Da3E68584421937E5F564A0135b;
    
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            stake_png_rewards,
            png,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function _takeFeePngToSnob(uint256 _keep) internal {
        IERC20(png).safeApprove(pangolinRouter, 0);
        IERC20(png).safeApprove(pangolinRouter, _keep);
        _swapPangolin(png, snob, _keep);
        uint _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    function harvest() public override onlyBenevolent {
        // Collects PNG tokens
        IStakingRewards(rewards).getReward();
        
        // Swap PNG for token
        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is locked up for future gov
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }
        }

        // We want to get back PNG LP tokens
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngXPngLp";
    }
}	