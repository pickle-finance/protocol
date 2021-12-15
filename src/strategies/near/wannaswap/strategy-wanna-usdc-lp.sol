// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaWannaUsdcLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_wanna_usdc_poolid = 9;
    // Token addresses
    address public wanna_wanna_usdc_lp =
        0x523faE29D7ff6FD38842c8F271eDf2ebd3150435;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            wanna,
            usdc,
            wanna_wanna_usdc_poolid,
            wanna_wanna_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [wanna, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaWannaUsdcLp";
    }
}
