// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaNearLunaLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_near_luna_poolid = 12;
    // Token addresses
    address public wanna_near_luna_lp =
        0x24f6c59747e4AcEB3DBA365df77D68c2A3aA4fB1;
    address public luna = 0xC4bdd27c33ec7daa6fcfd8532ddB524Bf4038096;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            near,
            luna,
            wanna_near_luna_poolid,
            wanna_near_luna_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
        swapRoutes[luna] = [wanna, near, luna];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaNearLunaLp";
    }
}
