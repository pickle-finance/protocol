// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettUsdtUsdcLp is StrategyNettFarmLPBase {
    uint256 public usdt_usdc_poolid = 10;
    // Token addresses
    address public usdt_usdc_lp = 0x7D02ab940d7dD2B771e59633bBC1ed6EC2b99Af1;
    address public usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address public usdt = 0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            usdt_usdc_poolid,
            usdt_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [nett, usdc];
        swapRoutes[usdt] = [nett, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettUsdtUsdcLp";
    }
}
