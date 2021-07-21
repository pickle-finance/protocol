// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyPngFarmBaseV2 is StrategyStakingRewardsBase {
    // Token addresses
    address public png = 0x60781C2586D68229fde47564546784ab3fACA982;

    // WAVAX/<token1> pair
    address public token1;

    // How much PNG tokens to keep?
    uint256 public keepPNG = 0;
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

        
}
