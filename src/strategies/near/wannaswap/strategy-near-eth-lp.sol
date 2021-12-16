// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaNearEthLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_near_eth_poolid = 4;
    // Token addresses
    address public wanna_near_eth_lp =
        0x256d03607eeE0156b8A2aB84da1D5B283219Fe97;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            near,
            eth,
            wanna_near_eth_poolid,
            wanna_near_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
        swapRoutes[eth] = [wanna, near, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaNearEthLp";
    }
}
