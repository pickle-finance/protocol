// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyTriAuroraEthLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_aurora_eth_poolid = 0;
    // Token addresses
    address public tri_aurora_eth_lp =
        0x5eeC60F348cB1D661E4A5122CF4638c7DB7A886e;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
            aurora,
            eth,
            tri_aurora_eth_poolid,
            tri_aurora_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[aurora] = [tri, aurora];
        swapRoutes[eth] = [tri, near, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriAuroraEthLp";
    }
}
