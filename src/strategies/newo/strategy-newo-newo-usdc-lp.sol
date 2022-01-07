// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-newo-farm-base.sol";

contract StrategyNewoNewoUsdcLp is StrategyFoxFarmBase {
    // Token addresses
    address public newo_newo_usdc_lp =
        0xB264dC9D22ece51aAa6028C5CBf2738B684560D6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFoxFarmBase(
            newo,
            newo_newo_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNewoNewoUsdcLp";
    }
}
