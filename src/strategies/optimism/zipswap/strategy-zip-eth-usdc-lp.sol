// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-zip-farm-base.sol";

contract StrategyZipEthUsdcLp is StrategyZipFarmBase {
    uint256 public constant eth_usdc_poolid = 0;
    // Token addresses
    address public constant eth_usdc_lp =
        0x1A981dAa7967C66C3356Ad044979BC82E4a478b9;
    address public constant usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyZipFarmBase(
            eth_usdc_lp,
            eth_usdc_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [zip, weth, usdc];
        swapRoutes[weth] = [zip, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyZipEthUsdcLp";
    }
}
