// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sushi-farm-base.sol";

contract StrategySushiEthWBtcLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public sushi_wbtc_poolId = 21;
    // Token addresses
    address public sushi_eth_wbtc_lp = 0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58;
    address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySushiFarmBase(
            wbtc,
            sushi_wbtc_poolId,
            sushi_eth_wbtc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthWBtcLp";
    }
}
