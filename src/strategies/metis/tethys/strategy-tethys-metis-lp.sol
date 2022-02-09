// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysMetisLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public tethys_metis_poolId = 0;
    address public tethys_metis_lp = 0xc9b290FF37fA53272e9D71A0B13a444010aF4497;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            tethys_metis_lp,
            tethys_metis_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [tethys, metis];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysMetisLp";
    }
}
