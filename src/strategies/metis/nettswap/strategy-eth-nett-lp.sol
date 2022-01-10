// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-netswap-base.sol";

contract StrategyNettEthNettLp is StrategyNettFarmLPBase {
    uint256 public eth_nett_poolid = 3;
    // Token addresses
    address public eth_nett_lp = 0xC8aE82A0ab6AdA2062B812827E1556c0fa448dd0;
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
            nett,
            eth_nett_poolid,
            eth_nett_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [nett, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettEthNettLp";
    }
}
