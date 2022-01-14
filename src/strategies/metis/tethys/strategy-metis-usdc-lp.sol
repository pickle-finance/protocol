// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tethys-base.sol";

contract StrategyTethysMetisUsdcLp is StrategyTethysFarmLPBase {
    // Token addresses
    uint256 public metis_usdc_poolId = 2;
    address public metis_usdc_lp = 0xDd7dF3522a49e6e1127bf1A1d3bAEa3bc100583B;
    address public usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTethysFarmLPBase(
            metis_usdc_lp,
            metis_usdc_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [tethys, metis];
        swapRoutes[usdc] = [tethys, metis, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTethysMetisUsdcLp";
    }
}
