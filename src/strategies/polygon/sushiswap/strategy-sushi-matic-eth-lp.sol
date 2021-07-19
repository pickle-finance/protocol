// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiMaticEthLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_matic_eth_poolId = 0;
    // Token addresses
    address public sushi_matic_eth_lp = 0xc4e595acDD7d12feC385E5dA5D43160e8A0bAC0E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            wmatic,
            weth,
            sushi_matic_eth_poolId,
            sushi_matic_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiMaticEthLp";
    }
}
