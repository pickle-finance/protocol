// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooBtcEthLp is StrategyBooFarmLPBase {
    uint256 public btc_eth_poolid = 35;
    // Token addresses
    address public btc_eth_lp = 0xEc454EdA10accdD66209C57aF8C12924556F3aBD;
    address public eth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address public btc = 0x321162Cd933E2Be498Cd2267a90534A804051b11;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettFarmLPBase(
            btc_eth_lp,
            btc_eth_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[btc] = [boo, ftm, btc];
        swapRoutes[eth] = [boo, ftm, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooBtcEthLp";
    }
}
