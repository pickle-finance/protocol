// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./farmbase-nett-metis-relay.sol";

contract StrategyNettMetisRelayLp is StrategyNettBtcMetisLPBase {
    uint256 public metis_relay_poolid = 11;
    // Token addresses
    address public metis_relay_lp = 0xA58bd557BFBC12f8cEaCcc6E1668F5FBFB2118BB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNettBtcMetisLPBase(
            metis_relay_lp,
            metis_relay_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [nett, metis];
        swapRoutes[relay] = [nett, metis, relay];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyNettMetisRelayLp";
    }
}
