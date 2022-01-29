// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-hades-base.sol";

contract StrategyHadesMetisLp is StrategyHadesFarmBase {
    uint256 public hades_metis_poolid = 1;
    // Token addresses
    address public hades_metis_lp = 0x586f616Bb811F1b0dFa953FBF6DE3569e7919752;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyHadesFarmBase(
            hades_metis_lp,
            hades_metis_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[metis] = [hellshare, metis];
        swapRoutes[hades] = [hellshare, metis, hades];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyHadesMetisLp";
    }
}
