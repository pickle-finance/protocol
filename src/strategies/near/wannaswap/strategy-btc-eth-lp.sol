// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaBtcEthLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_btc_eth_poolid = 5;
    // Token addresses
    address public wanna_btc_eth_lp =
        0xf56997948d4235514Dcc50fC0EA7C0e110EC255d;
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
            eth,
            wanna_btc_eth_poolid,
            wanna_btc_eth_lp,
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
        return "StrategyWannaBtcEthLp";
    }
}
