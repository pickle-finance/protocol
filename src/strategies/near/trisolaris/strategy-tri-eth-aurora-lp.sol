// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base.sol";

contract StrategyTriAuroraEthLp is StrategyTriFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_eth_aurora_poolid = 6;
    // Token addresses
    address public tri_eth_aurora_lp =
        0x5eeC60F348cB1D661E4A5122CF4638c7DB7A886e;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            eth,
            aurora,
            tri_eth_aurora_poolid,
            tri_eth_aurora_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[aurora] = [tri, near, eth, aurora];
        swapRoutes[eth] = [tri, near, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriAuroraEthLp";
    }
}
