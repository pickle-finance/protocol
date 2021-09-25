// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyPngFarmBaseV2 is StrategyStakingRewardsBase {

    // WAVAX/<token1> pair
    address public token1;

    // How much PNG tokens to keep?
    uint256 public keepPNG = 1000;
    uint256 public constant keepPNGMax = 10000;

    constructor(
        address _token1,
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;
    }

    // **** Setters ****

    function setKeepPNG(uint256 _keepPNG) external {
        require(msg.sender == timelock, "!timelock");
        keepPNG = _keepPNG;
    }

        // **** State Mutations ****

    function _takeFeePngToSnob(uint256 _keepPNG) internal {
        IERC20(png).safeApprove(pangolinRouter, 0);
        IERC20(png).safeApprove(pangolinRouter, _keepPNG);
        _swapPangolin(png, snob, _keepPNG);
        uint _snob = IERC20(snob).balanceOf(address(this));
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob
        );
    }

        
}
