// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IChildChainGaugeRewardHelper {
    function claimRewards(address gauge, address user) external;

    function pendingRewards(
        address gauge,
        address user,
        address token
    ) external view returns (uint256);
}
