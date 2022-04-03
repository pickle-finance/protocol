// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for Solarchef contract
interface ISolarChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            address[] calldata addresses,
            address[] calldata symbols,
            uint256[] calldata decimals,
            uint256[] calldata amounts
        );

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 rewardLockedUp,
            uint256 nextHarvestUntil
        );

    function withdraw(uint256 _pid, uint256 _amount) external;
}
