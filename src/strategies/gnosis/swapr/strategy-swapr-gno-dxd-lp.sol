// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-swapr-base.sol";

contract StrategySwaprDxdGnoLp is StrategySwaprFarmBase {
    // Token addresses
    address public swapr_dxd_gno_lp = 0x558d777B24366f011E35A9f59114D1b45110d67B;
    address public rewarderContract = 0x6148399F63c3dfdDf33A77c63A87C54e597D80E5;
    uint256 public rewards = 2;
    address public dxd = 0xb90D6bec20993Be5d72A5ab353343f7a0281f158;

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
            swapr_dxd_gno_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        rewardRoutes[swapr] = [swapr, xdai, gno];
        rewardRoutes[gno] = [gno];
        swapRoutes[dxd] = [gno, dxd];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySwaprDxdGnoLp";
    }
}
