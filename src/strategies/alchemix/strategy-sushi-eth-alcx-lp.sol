// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-alcx-farm-base.sol";

contract StrategySushiEthAlcxLp is StrategyAlcxFarmBase {

    uint256 public sushi_alcx_poolId = 2;

    address public sushi_eth_alcx_lp = 0xC3f279090a47e80990Fe3a9c30d24Cb117EF91a8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAlcxFarmBase(
            sushi_alcx_poolId,
            sushi_eth_alcx_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthAlcxLp";
    }
}
