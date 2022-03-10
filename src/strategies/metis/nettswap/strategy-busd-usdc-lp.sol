// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettBusdUsdcLp is StrategyNettFarmLPBase {
    uint256 public busd_usdc_poolid = 15;
    // Token addresses
    address public busd_usdc_lp = 0x8014c801F6cF32445D503f7BaC30976B3161eE52;
    address public usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address public busd = 0x12D84f1CFe870cA9C9dF9785f8954341d7fbb249;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            busd_usdc_lp,
            busd_usdc_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[busd] = [nett, usdc, busd];
        swapRoutes[usdc] = [nett, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettBusdUsdcLp";
    }
}
