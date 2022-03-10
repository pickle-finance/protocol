// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-dual-base.sol";

contract StrategyNettBinaryDAOUsdcLp is StrategyNettDualFarmLPBase {
    uint256 public binaryDAO_usdc_poolid = 16;
    // Token addresses
    address public binaryDAO_usdc_lp =
        0x3Ab6be89ED5A0d4FDD412c246F5e6DdD250Dd45c;
    address public usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address public binaryDAO = 0x721532bC0dA5ffaeB0a6A45fB24271E8098629A7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettDualFarmLPBase(
            binaryDAO_usdc_lp,
            binaryDAO_usdc_poolid,
            metis,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [nett, usdc];
        swapRoutes[binaryDAO] = [nett, usdc, binaryDAO];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettBinaryDAOUsdcLp";
    }
}
