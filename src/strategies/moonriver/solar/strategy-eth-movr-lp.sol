// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyEthMovrLp is StrategySolarFarmBase {
    uint256 public eth_movr_poolId = 1;

    // Token addresses
    address public eth_movr_lp = 0x0d171b55fC8d3BDDF17E376FdB2d90485f900888;
    address public movr = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
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
        uniswapRoutes[eth] = [solar, eth];
        uniswapRoutes[movr] = [solar, movr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyEthMovrLp";
    }
}
