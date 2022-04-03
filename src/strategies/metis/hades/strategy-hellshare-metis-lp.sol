// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-hades-base.sol";

contract StrategyHellshareMetisLp is StrategyHadesFarmBase {
    uint256 public hellshare_metis_poolid = 0;
    // Token addresses
    address public hellshare_metis_lp = 0xCD1cc85DC7b4Deef34247CCB5d7C42A58039b1bA;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyHadesFarmBase(
            hellshare_metis_lp,
            hellshare_metis_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [hellshare, metis];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyHellshareMetisLp";
    }
}
