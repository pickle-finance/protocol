// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthDaiLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_dai_poolId = 2;
    // Token addresses
    address public sushi_eth_dai_lp = 0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            dai,
            sushi_dai_poolId,
            sushi_eth_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthDaiLp";
    }
}
