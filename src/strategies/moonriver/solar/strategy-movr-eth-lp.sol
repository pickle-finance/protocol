// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-baseV2.sol";

contract StrategyEthMovrLp is StrategySolarFarmBaseV2 {
    uint256 public eth_movr_poolId = 1;

    // Token addresses
    address public eth_movr_lp = 0x0d171b55fC8d3BDDF17E376FdB2d90485f900888;
    address public eth = 0x639A647fbe20b6c8ac19E48E2de44ea792c62c5C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBaseV2(
            eth,
            movr,
            eth_movr_poolId,
            eth_movr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[eth] = [solar, movr, eth];
        uniswapRoutes[movr] = [solar, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySolarUsdcLp";
    }
}
