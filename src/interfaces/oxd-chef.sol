// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for Oxdchef contract
interface IOxdChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function pendingOXD(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt
        );

    function withdraw(uint256 _pid, uint256 _amount) external;
}
