// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-tri-base-dual-v2.sol";

contract StrategyTriUsdoUsdtLp is StrategyTriDualFarmBaseV2 {
    // Token/usdo pool id in MasterChef contract
    uint256 public tri_usdo_usdt_poolid = 16;
    // Token addresses
    address public tri_usdo_usdt_lp =
        0x6277f94a69Df5df0Bc58b25917B9ECEFBf1b846A;
    address public usdo = 0x293074789b247cab05357b08052468B5d7A23c5a;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyTriDualFarmBaseV2(
            tri_usdo_usdt_poolid,
            tri_usdo_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        // NEAR
        extraReward = 0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d;
        swapRoutes[tri] = [extraReward, tri];
        swapRoutes[usdo] = [tri, usdt, usdo];
        swapRoutes[usdt] = [tri, usdt];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyTriUsdoUsdtLp";
    }
}
