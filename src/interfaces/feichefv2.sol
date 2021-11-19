// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for Fei TribalChief contract
interface IFeichefV2 {
    function rewarder(uint256 pid) external view returns (address);

    function deposit(
        uint256 pid,
        uint256 amount,
        uint64 lockLength
    ) external;

    function pendingRewards(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            uint256 virtualTotalSupply,
            uint256 accTribePerShare,
            uint128 lastRewardBlock,
            uint120 allocPoint,
            bool unlocked
        );

    function harvest(uint256 pid, address to) external;

    function totalAllocPoint() external view returns (uint256);

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (int256 rewardDebt, uint256 virtualAmount);

    function depositInfo(
        uint256,
        address,
        uint256
    )
        external
        view
        returns (
            uint256 amount,
            uint128 unlockBlock,
            uint128 multiplier
        );

    function openUserDeposits(uint256 pid, address user)
        external
        view
        returns (uint256);

    function withdrawFromDeposit(
        uint256 pid,
        uint256 amount,
        address to,
        uint256 index
    ) external;

    function withdrawAllAndHarvest(uint256 pid, address to) external;
}
