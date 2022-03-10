// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysMetisAvaxLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public metis_avax_poolId = 8;
    address public metis_avax_lp = 0x3Ca47677e7D8796e6470307Ad15c1fBFd43f0D6F;
    address public avax = 0xE253E0CeA0CDD43d9628567d097052B33F98D611;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            metis_avax_lp,
            metis_avax_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [tethys, metis];
        swapRoutes[avax] = [tethys, metis, avax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysMetisAvaxLp";
    }
}
