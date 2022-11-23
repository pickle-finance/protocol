// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-base.sol";

import "../../interfaces/curve.sol";

// Base contract for Curve based staking contract interfaces
abstract contract StrategyCurveBase is StrategyBase {
    using SafeERC20 for IERC20;

    // curve dao
    address public gauge;
    address public curve;

    // token addresses
    address public usdc = 0xfA9343C3897324496A05fC75abeD6bAC29f8A40f;

    constructor(
        address _curve,
        address _gauge,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBase(_want, _governance, _strategist, _controller, _timelock) {
        curve = _curve;
        gauge = _gauge;
    }

    // **** Getters ****

    function balanceOfPool() public view override returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    // **** State Mutation functions ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, 0);
            IERC20(want).safeApprove(gauge, _want);
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }
}
