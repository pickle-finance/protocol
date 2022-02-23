// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettBtcUsdtLp is StrategyNettFarmLPBase {
    uint256 public btc_usdt_poolid = 14;
    // Token addresses
    address public btc_usdt_lp = 0xAd9b903451dfdc3D79d2021289F9d864fd8c8119;
    address public btc = 0xa5B55ab1dAF0F8e1EFc0eB1931a957fd89B918f4;
    address public usdt = 0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            btc_usdt_lp,
            btc_usdt_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [nett, usdt];
        swapRoutes[btc] = [nett, metis, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettBtcUsdtLp";
    }
}
