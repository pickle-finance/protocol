// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxCycleLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_cycle_lp_rewards =
        0x45cd033361E9fEF750AAea96DbC360B342F4b4a2;
    address public png_avax_cycle_lp =
        0x51486D916A273bEA3AE1303fCa20A76B17bE1ECD;
    address public cycle = 0x81440C939f2C1E34fc7048E518a637205A632a74;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            cycle,
            png_avax_cycle_lp_rewards,
            png_avax_cycle_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxCycleLp";
    }
}
