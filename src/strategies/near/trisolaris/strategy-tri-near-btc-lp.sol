// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base.sol";

contract StrategyTriNearBtcLp is StrategyTriFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_near_btc_poolid = 4;
    // Token addresses
    address public tri_near_btc_lp = 0xbc8A244e8fb683ec1Fd6f88F3cc6E565082174Eb;
    address public btc = 0xF4eB217Ba2454613b15dBdea6e5f22276410e89e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            near,
            btc,
            tri_near_btc_poolid,
            tri_near_btc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
        swapRoutes[btc] = [tri, near, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriNearBtcLp";
    }
}
