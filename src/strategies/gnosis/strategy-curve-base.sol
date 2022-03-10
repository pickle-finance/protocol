// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";

import "../../interfaces/curve.sol";

// Base contract for Curve based staking contract interfaces

abstract contract StrategyCurveBase is StrategyBase {
    // curve dao
    address public gauge;
    address public curve;
    // address public mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // stablecoins
    address public usdc = 0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83;
    address public usdt = 0x4ECaBa5870353805a9F068101A40E0f32ed605C6;

    // bitcoins
    address public wbtc = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;

    // rewards
    address public crv = 0x712b3d230F3C1c19db860d80619288b1F0BDd0Bd;

    // How much REWARD tokens to keep
    uint256 public keepREWARD = 420;
    uint256 public keepREWARDMax = 10000;

    mapping(address => address[]) public swapRoutes;

    constructor(
        address _curve,
        address _gauge,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_want, _governance, _strategist, _controller, _timelock) {
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

    function getMostPremium() public view virtual returns (address, uint256);

    // **** Setters ****

    function setKeepREWARD(uint256 _keepREWARD) external {
        require(msg.sender == governance, "!governance");
        keepREWARD = _keepREWARD;
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
