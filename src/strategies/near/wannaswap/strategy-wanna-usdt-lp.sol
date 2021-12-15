// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaWannaUsdtLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_wanna_usdt_poolid = 10;
    // Token addresses
    address public wanna_wanna_usdt_lp =
        0xcA461686C711AeaaDf0B516f9C2ad9d9B645a940;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            wanna,
            usdt,
            wanna_wanna_usdt_poolid,
            wanna_wanna_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [wanna, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaWannaUsdtLp";
    }
}
