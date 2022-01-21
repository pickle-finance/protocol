// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-zip-farm-base.sol";

contract StrategyZipEthBtcLp is StrategyZipFarmBase {
    uint256 public constant weth_btc_poolid = 2;
    // Token addresses
    address public constant weth_btc_lp =
        0x251de0f0368c472Bba2E1C8f5Db5aC7582B5f847;
    address public constant btc = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyZipFarmBase(
            weth_btc_lp,
            weth_btc_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[btc] = [zip, weth, btc];
        swapRoutes[weth] = [zip, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyZipEthBtcLp";
    }
}
