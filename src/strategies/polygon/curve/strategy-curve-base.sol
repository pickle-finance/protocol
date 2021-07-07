// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";

import "../../../interfaces/curve.sol";

// Base contract for Curve based staking contract interfaces

abstract contract StrategyCurveBase is StrategyBase {
    // curve dao
    address public gauge;
    address public curve;

    // stablecoins
    address public dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    // rewards
    address public crv = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;

    // How much CRV tokens to keep
    uint256 public keepCRV = 0;
    uint256 public keepCRVMax = 10000;

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
    }

    // **** Getters ****

    function balanceOfPool() public override view returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    function getMostPremium() public virtual view returns (address, uint256);

    // **** Setters ****

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
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

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }
}
