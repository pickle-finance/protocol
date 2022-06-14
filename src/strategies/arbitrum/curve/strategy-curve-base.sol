// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base.sol";

import "../../../interfaces/curve.sol";


// Base contract for Curve based staking contract interfaces

abstract contract StrategyCurveBase is StrategyBase {
    // curve dao
    address public gauge;
    address public curve;
    address public mintr = 0xabC000d88f23Bb45525E447528DBF656A9D55bf5;

    // rewards
    address public crv = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;

    constructor(
        address _curve,
        address _gauge,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        curve = _curve;
        gauge = _gauge;
        IERC20(want).safeApprove(gauge, type(uint256).max);
        IERC20(weth).safeApprove(curve, type(uint256).max);
    }

    // **** Getters ****

    function balanceOfPool() public override view returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    // **** State Mutation functions ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }
}
