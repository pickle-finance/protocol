// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base.sol";

contract StrategyTriEthNearLp is StrategyTriFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_eth_near_poolid = 1;
    // Token addresses
    address public tri_eth_near_lp = 0x63da4DB6Ef4e7C62168aB03982399F9588fCd198;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            eth,
            near,
            tri_eth_near_poolid,
            tri_eth_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [tri, near, eth];
        swapRoutes[near] = [tri, near];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriEthNearLp";
    }
}
