// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/masterchefv2.sol";
import "../interfaces/masterchef-rewarder.sol";

abstract contract StrategyMasterchefV2FarmBase is StrategyBase {
    // Token addresses
    address public constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    address public constant masterChef =
        0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d;

    uint256 public poolId;

    constructor(
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        poolId = _poolId;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) =
            IMasterchefV2(masterChef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
      uint256 _pendingSushi = IMasterchefV2(masterChef).pendingSushi(poolId, address(this));
      IMasterchefRewarder rewarder = IMasterchefRewarder(IMasterchefV2(masterChef).rewarder(poolId));
      (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(poolId, address(this), 0);

      uint256 _pendingReward;
      if (_rewardAmounts.length > 0) {
          _pendingReward = _rewardAmounts[0];
      }
      return (_pendingSushi, _pendingReward);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            IMasterchefV2(masterChef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterchefV2(masterChef).withdraw(poolId, _amount, address(this));
        return _amount;
    }
}