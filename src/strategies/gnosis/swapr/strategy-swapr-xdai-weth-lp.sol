// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-swapr-base.sol";

contract StrategySwaprWethXdaiLp is StrategySwaprFarmBase {
    // Token addresses
    address public swapr_weth_xdai_lp = 0x1865d5445010E0baf8Be2eB410d3Eae4A68683c2;
    address public rewarderContract = 0xCB3aAba65599341B5beb24b6001611077c5979E6;
    uint256 public rewards = 2;

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
            swapr_weth_xdai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[gno] = [swapr, xdai, gno];
        swapRoutes[weth] = [gno, weth];
        swapRoutes[xdai] = [gno, weth, xdai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprWethXdaiLp";
    }
}
