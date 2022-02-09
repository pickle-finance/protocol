// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-zip-farm-base.sol";

contract StrategyZipEthDaiLp is StrategyZipFarmBase {
    uint256 public constant eth_dai_poolid = 1;
    // Token addresses
    address public constant eth_dai_lp =
        0x53790B6C7023786659D11ed82eE03079F3bD6976;
    address public constant dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyZipFarmBase(
            eth_dai_lp,
            eth_dai_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[dai] = [zip, weth, dai];
        swapRoutes[weth] = [zip, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyZipEthDaiLp";
    }
}
