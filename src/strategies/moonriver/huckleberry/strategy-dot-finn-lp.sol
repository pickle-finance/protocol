// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-finn-farm-base.sol";

contract StrategyFinnMovrFinnLp is StrategyFinnFarmBase {
    uint256 public dot_finn_poolId = 7;

    // Token addresses
    address public dot_finn_lp = 0xF09211fb5eD5019b072774cfD7Db0c9f4ccd5Be0;
    address public dot = 0x15B9CA9659F5dfF2b7d35a98dd0790a3CBb3D445;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFinnFarmBase(
            dot,
            finn,
            dot_finn_poolId,
            dot_finn_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[dot] = [finn, dot];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFinnMovrFinnLp";
    }
}
