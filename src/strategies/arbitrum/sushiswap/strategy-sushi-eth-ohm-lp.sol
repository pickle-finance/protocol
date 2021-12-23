// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthOhmLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_ohm_eth_poolId = 12;
    // Token addresses
    address public sushi_ohm_eth_lp = 0xaa5bD49f2162ffdC15634c87A77AC67bD51C6a6D;
    address public ohm = 0x8D9bA570D6cb60C7e3e0F31343Efe75AB8E65FB1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            weth,
            ohm,
            sushi_ohm_eth_poolId,
            sushi_ohm_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        rewardToken = ohm;
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthOhmLp";
    }
}
