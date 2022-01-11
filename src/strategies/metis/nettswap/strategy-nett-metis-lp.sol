// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettNettMetisLp is StrategyNettFarmLPBase {
    uint256 public nett_metis_poolid = 2;
    // Token addresses
    address public nett_metis_lp = 0x60312d4EbBF3617d3D33841906b5868A86931Cbd;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            nett_metis_poolid,
            nett_metis_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [nett, metis];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettNettMetisLp";
    }
}
