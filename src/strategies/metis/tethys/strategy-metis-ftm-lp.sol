// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysMetisFtmLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public metis_ftm_poolId = 7;
    address public metis_ftm_lp = 0x74Ca39F7aB9B685B8eA8c4ab19E7Ab6b474Dd22D;
    address public ftm = 0xa9109271abcf0C4106Ab7366B4eDB34405947eED;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            metis_ftm_lp,
            metis_ftm_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [tethys, metis];
        swapRoutes[ftm] = [tethys, metis, ftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysMetisFtmLp";
    }
}
