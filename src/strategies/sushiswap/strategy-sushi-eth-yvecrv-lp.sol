// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthYVeCrvLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_yvecrv_poolId = 132;
    // Token addresses
    address public sushi_eth_yvecrv_lp = 0x10B47177E92Ef9D5C6059055d92DdF6290848991;
    address public yvecrv = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            yvecrv,
            sushi_yvecrv_poolId,
            sushi_eth_yvecrv_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthYVeCRVLp";
    }
}
