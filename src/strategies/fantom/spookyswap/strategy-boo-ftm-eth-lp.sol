// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmEthLp is StrategyBooFarmLPBase {
    uint256 public ftm_eth_poolid = 5;
    // Token addresses
    address public ftm_eth_lp = 0xf0702249F4D3A25cD3DED7859a165693685Ab577;
    address public eth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            ftm_eth_lp,
            ftm_eth_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[ftm] = [boo, ftm];
        swapRoutes[eth] = [boo, ftm, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmEthLp";
    }
}
