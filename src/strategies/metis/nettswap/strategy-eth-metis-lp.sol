// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettEthMetisLp is StrategyNettFarmLPBase {
    uint256 public eth_metis_poolid = 5;
    // Token addresses
    address public eth_metis_lp = 0x59051B5F5172b69E66869048Dc69D35dB0B3610d;
    address public eth = 0x420000000000000000000000000000000000000A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            eth_metis_lp,
            eth_metis_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [nett, metis];
        swapRoutes[eth] = [nett, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettEthMetisLp";
    }
}
