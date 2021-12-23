// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiMagicEthLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_magic_eth_poolId = 13;
    // Token addresses
    address public sushi_magic_eth_lp = 0xB7E50106A5bd3Cf21AF210A755F9C8740890A8c9;
    address public magic = 0x539bdE0d7Dbd336b79148AA742883198BBF60342;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            magic,
            weth,
            sushi_magic_eth_poolId,
            sushi_magic_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        rewardToken = magic;
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiMagicEthLp";
    }
}
