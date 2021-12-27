// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaUstNearLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_ust_near_poolid = 13;
    // Token addresses
    address public wanna_ust_near_lp =
        0x436C525D536adC447c7775575f88D357634734C1;
    address public ust = 0x5ce9F0B6AFb36135b5ddBF11705cEB65E634A9dC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            ust,
            near,
            wanna_ust_near_poolid,
            wanna_ust_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
        swapRoutes[ust] = [wanna, near, ust];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaUstNearLp";
    }
}
