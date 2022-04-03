// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaEthBtcLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_eth_btc_poolid = 5;
    // Token addresses
    address public wanna_eth_btc_lp =
        0xf56997948d4235514Dcc50fC0EA7C0e110EC255d;
    address public btc = 0xF4eB217Ba2454613b15dBdea6e5f22276410e89e;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            eth,
            btc,
            wanna_eth_btc_poolid,
            wanna_eth_btc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [wanna, near, eth];
        swapRoutes[btc] = [wanna, near, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaEthBtcLp";
    }
}
