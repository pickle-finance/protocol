// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-zip-farm-dual-base.sol";

contract StrategyZipEthGohmLp is StrategyZipFarmDualBase {
    uint256 public constant eth_gohm_poolid = 5;
    // Token addresses
    address public constant eth_gohm_lp =
        0x3f6da9334142477718bE2ecC3577d1A28dceAAe1;
    address public gohm = 0x0b5740c6b4a97f90eF2F0220651Cca420B868FfB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyZipFarmDualBase(
            extraRewardBool,
            gohm,
            eth_gohm_lp,
            eth_gohm_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        extraRewardBool = true;
        extraReward = gohm;
        swapRoutes[gohm] = [zip, weth, gohm];
        swapRoutes[weth] = [gohm, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyZipEthGohmLp";
    }
}
