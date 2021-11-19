
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cherry-farm-base.sol";

contract StrategyCherryCheUsdtLp is StrategyCherryFarmBase {
    uint256 public che_usdt_poolId = 2;

    // Token addresses
    address public cherry_che_usdt_lp = 0x089dedbFD12F2aD990c55A2F1061b8Ad986bFF88;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCherryFarmBase(
            usdt,
            cherry,
            che_usdt_poolId,
            cherry_che_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyCherryCheUsdtLp";
    }
}
