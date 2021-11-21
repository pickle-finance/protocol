// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthBitLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_bit_poolId = 2;
    // Token addresses
    address public sushi_eth_bit_lp =
        0xE12af1218b4e9272e9628D7c7Dc6354D137D024e;
    address public bit = 0x1a4b46696b2bb4794eb3d4c26f1c55f9170fa4c5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            bit,
            sushi_bit_poolId,
            sushi_eth_bit_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthBitLp";
    }
}
