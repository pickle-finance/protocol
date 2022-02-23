// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-zip-farm-base.sol";

contract StrategyZipEthZipLp is StrategyZipFarmBase {
    uint256 public constant eth_zip_poolid = 3;
    // Token addresses
    address public constant eth_zip_lp =
        0xD7F6ECF4371eddBd60C1080BfAEc3d1d60D415d0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyZipFarmBase(
            eth_zip_lp,
            eth_zip_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[weth] = [zip, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyZipEthZipLp";
    }
}
