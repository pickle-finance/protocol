// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettMetisUsdcLp is StrategyNettSwapBase {
    uint256 public metis_usdc_poolid = 7;
    // Token addresses
    address public metis_usdc_lp = 0x5Ae3ee7fBB3Cb28C17e7ADc3a6Ae605ae2465091;
    address public usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettSwapFarmBase(
            metis,
            usdc,
            metis_usdc_poolid,
            metis_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [nett, metis];
        swapRoutes[usdc] = [nett, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettMetisUsdcLp";
    }
}
