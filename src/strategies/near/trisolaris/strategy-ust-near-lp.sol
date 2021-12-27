// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual.sol";

contract StrategyUstNearLp is StrategyTriDualFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public ust_near_poolid = 3;
    // Token addresses
    address public ust_near_lp = 0xa9eded3E339b9cd92bB6DEF5c5379d678131fF90;
    address public ust = 0x5ce9F0B6AFb36135b5ddBF11705cEB65E634A9dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBase(
            ust,
            near,
            ust_near_poolid,
            ust_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
        swapRoutes[ust] = [tri, near, ust];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUstNearLp";
    }
}
