// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-sorbetto-base.sol";

contract StrategySorbettoEthUsdtLp is StrategySorbettoBase {
    // Token addresses
    address public popsicle_eth_usdt_lp = 0xc4ff55a4329f84f9Bf0F5619998aB570481EBB48;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySorbettoBase(
          weth,
          usdt,
          popsicle_eth_usdt_lp,
          _governance,
          _strategist,
          _controller,
          _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySorbettoEthUsdtLp";
    }
}
