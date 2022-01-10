// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettNettUsdtLp is StrategyNettFarmLPBase {
    uint256 public nett_usdt_poolid = 0;
    // Token addresses
    address public nett_usdt_lp = 0x7D02ab940d7dD2B771e59633bBC1ed6EC2b99Af1;
    address public usdt = 0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            nett,
            usdt,
            nett_usdt_poolid,
            nett_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [nett, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettNettUsdtLp";
    }
}
