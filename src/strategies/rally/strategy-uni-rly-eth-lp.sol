// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-rally-farm-base.sol";

contract StrategyRlyEthLp is StrategyRallyFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public rly_eth_poolId = 0;
    // Token addresses
    address public uni_eth_rly_lp = 0x27fD0857F0EF224097001E87e61026E39e1B04d1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyRallyFarmBase(
            rally,
            rly_eth_poolId,
            uni_eth_rly_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyRallyFarmBase";
    }
}
