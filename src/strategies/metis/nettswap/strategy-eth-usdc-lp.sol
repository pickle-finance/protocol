// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettEthUsdcLp is StrategyNettFarmLPBase {
    uint256 public eth_usdc_poolid = 9;
    // Token addresses
    address public eth_usdc_lp = 0xF5988809ac97C65121e2c34f5D49558e3D12C253;
    address public usdc = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address public eth = 0x420000000000000000000000000000000000000A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            eth,
            usdc,
            eth_usdc_poolid,
            eth_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [nett, usdc];
        swapRoutes[eth] = [nett, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettEthUsdcLp";
    }
}
