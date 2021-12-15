// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaBtcNearLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_btc_near_poolid = 0;
    // Token addresses
    address public wanna_btc_near_lp =
        0xbF58062D23f869a90c6Eb04B9655f0dfCA345947;
    address public btc = 0xF4eB217Ba2454613b15dBdea6e5f22276410e89e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            btc,
            near,
            wanna_btc_near_poolid,
            wanna_btc_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
        swapRoutes[btc] = [wanna, near, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaBtcNearLp";
    }
}
