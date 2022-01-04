// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlNearBtcLp is StrategyBrlFarmBase {
    uint256 public near_btc_poolid = 5;
    // Token addresses
    address public near_btc_lp = 0xe11A3f2BAB372d88D133b64487D1772847Eec4eA;
    address public btc = 0xF4eB217Ba2454613b15dBdea6e5f22276410e89e;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            near,
            btc,
            near_btc_poolid,
            near_btc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[btc] = [brl, near, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlNearBtcLp";
    }
}
