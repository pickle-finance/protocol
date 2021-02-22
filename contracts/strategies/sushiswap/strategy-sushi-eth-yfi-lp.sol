// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthYfiLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_yfi_poolId = 11;
    // Token addresses
    address public sushi_eth_yfi_lp = 0x088ee5007C98a9677165D78dD2109AE4a3D04d0C;
    address public yfi = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            yfi,
            sushi_yfi_poolId,
            sushi_eth_yfi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthYfiLp";
    }
}
