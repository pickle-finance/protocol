// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-dual-base.sol";

contract StrategyNettWbtcMetisLp is StrategyNettDualFarmLPBase {
    uint256 public btc_metis_poolid = 13;
    // Token addresses
    address public btc_metis_lp = 0xE0cc462fe369146BAef2306EC6B4BF26704eE84e;
    address public wbtc = 0xa5B55ab1dAF0F8e1EFc0eB1931a957fd89B918f4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettDualFarmLPBase(
            btc_metis_lp,
            btc_metis_poolid,
            metis,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [nett, metis];
        swapRoutes[wbtc] = [metis, wbtc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettWbtcMetisLp";
    }
}
