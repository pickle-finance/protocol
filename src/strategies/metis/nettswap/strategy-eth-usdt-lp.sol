// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettEthUsdtLp is StrategyNettSwapBase {
    uint256 public eth_usdt_poolid = 8;
    // Token addresses
    address public eth_usdt_lp = 0x4Db4CE7f5b43A6B455D3c3057b63A083b09b8376;
    address public usdt = 0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC;
    address public eth = 0x420000000000000000000000000000000000000A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettSwapFarmBase(
            eth,
            usdt,
            eth_usdt_poolid,
            eth_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [nett, usdt];
        swapRoutes[eth] = [nett, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettEthUsdtLp";
    }
}
