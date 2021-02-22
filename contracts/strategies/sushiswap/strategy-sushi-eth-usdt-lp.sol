// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthUsdtLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_usdt_poolId = 0;
    // Token addresses
    address public sushi_eth_usdt_lp = 0x06da0fd433C1A5d7a4faa01111c044910A184553;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            usdt,
            sushi_usdt_poolId,
            sushi_eth_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthUsdtLp";
    }
}
