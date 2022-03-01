// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

interface IBeethovenxMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accBeetsPerShare;
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

    function harvest(uint256 _pid, address _to) external;

    function pendingBeets(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending);
}
