// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettNettUsdcLp is StrategyNettFarmLPBase {
    uint256 public nett_usdc_poolid = 1;
    // Token addresses
    address public nett_usdc_lp = 0x0724d37522585E87d27C802728E824862Dc72861;
    address public usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            nett_usdc_poolid,
            nett_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [nett, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettNettUsdcLp";
    }
}
