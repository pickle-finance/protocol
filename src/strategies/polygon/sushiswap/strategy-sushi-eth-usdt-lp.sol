// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthUsdtLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_usdt_poolId = 2;
    // Token addresses
    address public sushi_eth_usdt_lp = 0xc2755915a85C6f6c1C0F3a86ac8C058F11Caa9C9;
    address public usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            weth,
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
