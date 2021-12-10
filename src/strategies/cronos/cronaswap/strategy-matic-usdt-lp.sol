// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaMaticUsdtLp is StrategyCronaFarmBase {
    uint256 public matic_usdt_poolId = 6;

    // Token addresses
    address public matic_usdt_lp = 0x394080F7c770771B6EE4f4649bC477F0676ceA5C;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address public matic = 0xc9BAA8cfdDe8E328787E29b4B078abf2DaDc2055;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            matic,
            usdt,
            matic_usdt_poolId,
            matic_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [crona, usdt];
        uniswapRoutes[matic] = [crona, usdt, matic];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaMaticUsdtLp";
    }
}
