// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-finn-farm-base.sol";

contract StrategyFinnFinnRmrkLp is StrategyFinnFarmBase {
    uint256 public finn_rmrk_poolId = 31;

    // Token addresses
    address public finn_rmrk_lp = 0xd9e98aD7AE9E5612b90cd0bdcD82df4FA5b943b8;
    address public rmrk = 0xffffffFF893264794d9d57E1E0E21E0042aF5A0A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFinnFarmBase(
            finn,
            rmrk,
            finn_rmrk_poolId,
            finn_rmrk_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[rmrk] = [finn, rmrk];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFinnFinnRmrkLp";
    }
}
