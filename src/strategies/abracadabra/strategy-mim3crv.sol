// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-abracadabra-base.sol";

contract StrategyMim3crvLp is StrategyAbracadabraFarmBase {
    address public mim_3crv = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    uint256 public mim_poolid = 1;

    address public mim = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address public zapper = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAbracadabraFarmBase(
            mim_3crv,
            mim_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyMim3crvLp";
    }

    function harvest() public override onlyBenevolent {
        ISorbettiereFarm(sorbettiere).deposit(poolId, 0);
        uint256 _ice = IERC20(ice).balanceOf(address(this));
        if (_ice > 0) {
            // 10% is locked up for future gov
            uint256 _keepIce = _ice.mul(keepIce).div(keepIceMax);
            IERC20(ice).safeTransfer(
                IController(controller).treasury(),
                _keepIce
            );
            uint256 _swap = _ice.sub(_keepIce);
            IERC20(ice).safeApprove(sushiRouter, 0);
            IERC20(ice).safeApprove(sushiRouter, _swap);
            _swapSushiswap(ice, mim, _swap);
        }

        uint256 _mim = IERC20(mim).balanceOf(address(this));
        if (_mim > 0) {
            IERC20(mim).safeApprove(zapper, 0);
            IERC20(mim).safeApprove(zapper, _mim);

            uint256[4] memory amounts = [_mim, 0, 0, 0];
            ICurveZapper(zapper).add_liquidity(mim_3crv, amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
