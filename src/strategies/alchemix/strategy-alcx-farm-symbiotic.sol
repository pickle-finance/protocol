// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base-symbiotic.sol";
import "../../interfaces/alcx-farm.sol";
import "../../interfaces/convex-farm.sol";

abstract contract StrategyAlcxSymbioticFarmBase is StrategyBaseSymbiotic {
    // How much Alcx tokens to keep?
    uint256 public keepAlcx = 1000;
    uint256 public constant keepAlcxMax = 10000;

    uint256 public alcxPoolId = 1;

    uint256 public alusdPoolId = 36;

    constructor(
        address _token,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBaseSymbiotic(
            _token,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getCrvRewardContract() public view returns (address) {
        (, , , address crvRewards, , ) =
            IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31).poolInfo(
                alusdPoolId
            );
        return crvRewards;
    }

    function getAlcxRewardContract() public view returns (address) {
        return IBaseRewardPool(getCrvRewardContract()).extraRewards(0);
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount =
            IBaseRewardPool(getCrvRewardContract()).balanceOf(address(this));
        return amount;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(convexBooster, 0);
            IERC20(want).safeApprove(convexBooster, _want);

            IConvexBooster(convexBooster).deposit(alusdPoolId, _want, true);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBaseRewardPool(getCrvRewardContract()).withdrawAndUnwrap(
            _amount,
            false
        );
        return _amount;
    }

    function _withdrawSomeReward(uint256 _amount)
        internal
        override
        returns (uint256)
    {
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
