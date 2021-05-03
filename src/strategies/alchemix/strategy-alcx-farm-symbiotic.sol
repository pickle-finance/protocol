// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base-symbiotic.sol";
import "../../interfaces/alcx-farm.sol";

abstract contract StrategyAlcxSymbioticFarmBase is StrategyBaseSymbiotic {

    // How much Alcx tokens to keep?
    uint256 public keepAlcx = 0;
    uint256 public constant keepAlcxMax = 10000;

    uint256 public alcxPoolId = 1;

    uint256 public poolId;

    constructor(
        uint256 _poolId,
        address _token,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBaseSymbiotic(_token, _governance, _strategist, _controller, _timelock) {
        poolId = _poolId;
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IStakingPools(stakingPool).getStakeTotalDeposited(address(this), poolId);
        return amount;
    }

    function getHarvestable() public view returns (uint256) {
        return IStakingPools(stakingPool).getStakeTotalUnclaimed(address(this), poolId);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingPool, 0);
            IERC20(want).safeApprove(stakingPool, _want);
            IStakingPools(stakingPool).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IStakingPools(stakingPool).withdraw(poolId, _amount);
        return _amount;
    }

    function _withdrawSomeReward(uint256 _amount) internal override returns (uint256) {
        IStakingPools(stakingPool).withdraw(alcxPoolId, _amount);
        return _amount;
    }

    function __redeposit() internal override {
        uint256 _balance = IERC20(alcx).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(alcx).safeApprove(stakingPool, 0);
            IERC20(alcx).safeApprove(stakingPool, _balance);
            IStakingPools(stakingPool).deposit(alcxPoolId, _balance); //stake to alcx farm
        }
    }

    // **** Setters ****

    function setKeepAlcx(uint256 _keepAlcx) external {
        require(msg.sender == timelock, "!timelock");
        keepAlcx = _keepAlcx;
    }
    // can't have harvest function here
}
