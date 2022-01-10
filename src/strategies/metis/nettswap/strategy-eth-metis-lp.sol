// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettEthMetisLp is StrategyNettSwapBase {
    uint256 public eth_metis_poolid = 5;
    // Token addresses
    address public eth_metis_lp = 0x60312d4EbBF3617d3D33841906b5868A86931Cbd;
    address public eth = 0x420000000000000000000000000000000000000A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettSwapFarmBase(
            eth,
            metis,
            eth_metis_poolid,
            eth_metis_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [eth, metis];
        swapRoutes[eth] = [nett, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettEthMetisLp";
    }
}
