// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettUsdtMetisLp is StrategyNettFarmLPBase {
    uint256 public usdt_metis_poolid = 6;
    // Token addresses
    address public usdt_metis_lp = 0x3D60aFEcf67e6ba950b499137A72478B2CA7c5A1;
    address public usdt = 0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            usdt_metis_poolid,
            usdt_metis_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [nett, metis];
        swapRoutes[usdt] = [nett, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettUsdtMetisLp";
    }
}
