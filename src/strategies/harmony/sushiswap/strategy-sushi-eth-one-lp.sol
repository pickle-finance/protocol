// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthOneLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_eth_one_poolId = 3;
    // Token addresses
    address public sushi_eth_one_lp = 0xeb049F1eD546F8efC3AD57f6c7D22F081CcC7375;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            weth,
            wone,
            sushi_eth_one_poolId,
            sushi_eth_one_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthOneLp";
    }
}
