// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiWbtcEthLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_wbtc_eth_poolId = 10;
    // Token addresses
    address public sushi_wbtc_eth_lp = 0x39bE7c95276954a6f7070F9BAa38db2123691Ed0;
    address public wbtc = 0x3095c7557bCb296ccc6e363DE01b760bA031F2d9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            wbtc,
            weth,
            sushi_wbtc_eth_poolId,
            sushi_wbtc_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiWbtcEthLp";
    }
}
