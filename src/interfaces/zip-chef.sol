// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for Zipchef contract
interface IZipChef {
    function deposit(
        uint256 _pid,
        uint128 _amount,
        address _to
    ) external;

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending);

    function userInfo(uint256, address)
        external
        view
        returns (uint128 amount, int128 rewardDebt);

    function harvest(uint256, address) external returns (uint256);

    function withdraw(
        uint256 _pid,
        uint128 _amount,
        address _to
    ) external;
}
