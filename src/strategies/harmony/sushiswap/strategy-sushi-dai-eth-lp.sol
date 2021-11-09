// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiDaiEthLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_dai_eth_poolId = 15;
    // Token addresses
    address public sushi_dai_eth_lp = 0xc5B8129B411EF5f5BE22e74De6fE86C3b69e641d;
    address public dai = 0xEf977d2f931C1978Db5F6747666fa1eACB0d0339;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            weth,
            dai,
            sushi_dai_eth_poolId,
            sushi_dai_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiDaiEthLp";
    }
}
