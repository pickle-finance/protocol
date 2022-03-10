// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-swapr-base.sol";

contract StrategySwaprGnoWethLp is StrategySwaprFarmBase {
    // Token addresses
    address public swapr_gno_weth_lp = 0x5fCA4cBdC182e40aeFBCb91AFBDE7AD8d3Dc18a8;
    address public rewarderContract = 0x40b37ba95f9BCf8930E6f8A65e5B4534518c3EAB;
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
            swapr_gno_weth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[gno] = [swapr, xdai, gno];
        swapRoutes[weth] = [gno, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprGnoWethLp";
    }
}
