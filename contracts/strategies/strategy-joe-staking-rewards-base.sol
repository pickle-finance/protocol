pragma solidity ^0.6.7;

import "./strategy-joe-base.sol";
import "../interfaces/istablejoestaking.sol";
//import "hardhat/console.sol";

// Base contract for SNX Staking staking contract interfaces

abstract contract StrategyJoeStakingRewardsBase is StrategyJoeBase {
    address public staking;
    address public reward;

    // **** Getters ****
    constructor(
        address _staking,
        address _want,
        address _reward,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJoeBase(_want, _governance, _strategist, _controller, _timelock)
    {
        staking = _staking;
        reward = _reward;
    }

    function balanceOfPool() public override view returns (uint256) {
        (uint256 amount,) = IStableJoeStaking(staking).getUserInfo(address(this), want);
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        IStableJoeStaking(staking).updateReward(reward);
        return IStableJoeStaking(staking).pendingReward(address(this), reward);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(staking, 0);
            IERC20(want).safeApprove(staking, _want);
            IStableJoeStaking(staking).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStableJoeStaking(staking).withdraw(_amount);
        return _amount;
    }
}
