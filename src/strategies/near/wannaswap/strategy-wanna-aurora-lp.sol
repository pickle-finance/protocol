// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaWannaAuroraLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_wanna_aurora_poolid = 16;
    // Token addresses
    address public wanna_wanna_aurora_lp =
        0xddCcf2F096fa400ce90ba0568908233e6A950961;
    address public aurora = 0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            wanna,
            aurora,
            wanna_wanna_aurora_poolid,
            wanna_wanna_aurora_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[aurora] = [wanna, aurora];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaWannaAuroraLp";
    }
}
