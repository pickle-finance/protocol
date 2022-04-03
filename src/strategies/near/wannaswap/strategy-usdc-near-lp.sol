// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaUsdcNearLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_usdc_near_poolid = 1;
    // Token addresses
    address public wanna_usdc_near_lp =
        0xBf560771B6002a58477EFBCDD6774A5a1947587B;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            usdc,
            near,
            wanna_usdc_near_poolid,
            wanna_usdc_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [wanna, near];
        swapRoutes[usdc] = [wanna, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaUsdcNearLp";
    }
}
