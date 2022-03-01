// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-finn-farm-base.sol";

contract StrategyFinnMovrFinnLp is StrategyFinnFarmBase {
    uint256 public movr_finn_poolId = 4;

    // Token addresses
    address public movr_finn_lp = 0xbBe2f34367972Cb37ae8dea849aE168834440685;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFinnFarmBase(
            movr,
            finn,
            movr_finn_poolId,
            movr_finn_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[movr] = [finn, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFinnMovrFinnLp";
    }
}
