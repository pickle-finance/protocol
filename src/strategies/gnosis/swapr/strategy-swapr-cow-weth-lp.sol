// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-swapr-base.sol";

contract StrategySwaprCowWethLp is StrategySwaprFarmBase {
    // Token addresses
    address public swapr_cow_weth_lp = 0x8028457E452D7221dB69B1e0563AA600A059fab1;

    address public rewarderContract = 0xDa72E71f84DC15c80941D70494D6BD8a623DCBB4;
    uint256 public rewards = 3;
    address public cow = 0x177127622c4A00F3d409B75571e12cB3c8973d3c;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySwaprFarmBase(
            rewarderContract,
            rewards,
            swapr_cow_weth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        rewardRoutes[swapr] = [swapr, xdai, gno];
        rewardRoutes[cow] = [cow, gno];
        rewardRoutes[gno] = [gno];
        swapRoutes[weth] = [gno, weth];
        swapRoutes[cow] = [gno, weth, cow];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprCowWethLp";
    }
}
