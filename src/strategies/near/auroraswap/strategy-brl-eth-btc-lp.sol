// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlEthBtcLp is StrategyBrlFarmBase {
    uint256 public eth_btc_poolid = 6;
    // Token addresses
    address public eth_btc_lp = 0xcb8584360Dc7A4eAC4878b48fB857AA794E46Fa8;
    address public btc = 0xF4eB217Ba2454613b15dBdea6e5f22276410e89e;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyNearPadFarmBase(
            eth,
            btc,
            eth_btc_poolid,
            eth_btc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [brl, eth];
        swapRoutes[btc] = [brl, near, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlEthBtcLp";
    }
}
