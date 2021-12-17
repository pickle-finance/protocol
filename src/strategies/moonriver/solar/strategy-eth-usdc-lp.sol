// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-solar-farm-base.sol";

contract StrategyEthUsdcLp is StrategySolarFarmBase {
    uint256 public eth_usdc_poolId = 10;

    // Token addresses
    address public eth_usdc_lp = 0xA0D8DFB2CC9dFe6905eDd5B71c56BA92AD09A3dC;
    address public usdc = 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D;
    address public eth = 0x639A647fbe20b6c8ac19E48E2de44ea792c62c5C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            eth,
            usdc,
            eth_usdc_poolId,
            eth_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[eth] = [solar, movr, eth];
        uniswapRoutes[usdc] = [solar, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyEthUsdcLp";
    }
}
