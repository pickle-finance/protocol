// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysUsdtMetisLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public usdt_metis_poolId = 1;
    address public usdt_metis_lp = 0x8121113eB9952086deC3113690Af0538BB5506fd;
    address public usdt = 0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            usdt,
            metis,
            usdt_metis_lp,
            usdt_metis_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[metis] = [tethys, metis];
        uniswapRoutes[usdt] = [tethys, metis, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysUsdtMetisLp";
    }
}
