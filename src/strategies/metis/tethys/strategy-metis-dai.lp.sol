// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysMetisDaiLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public metis_dai_poolId = 9;
    address public metis_dai_lp = 0xCc15d8f93be780aD78fD1A016fB0F15F2543b5Dc;
    address public dai = 0x4651B38e7ec14BB3db731369BFE5B08F2466Bd0A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            metis_dai_lp,
            metis_dai_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [tethys, metis];
        swapRoutes[dai] = [tethys, metis, dai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysMetisDaiLp";
    }
}
