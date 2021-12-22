// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base.sol";

contract StrategyTriNearUsdcLp is StrategyTriFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public tri_near_usdc_poolid = 1;
    // Token addresses
    address public tri_near_usdc_lp =
        0x20F8AeFB5697B77E0BB835A8518BE70775cdA1b0;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriFarmBase(
            near,
            usdc,
            tri_near_usdc_poolid,
            tri_near_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [tri, near];
        swapRoutes[usdc] = [tri, near, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriNearUsdcLp";
    }
}
