// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/erc20.sol";

// interface for Axial Rewarder contract
interface IMiniChefRewarder {
    using SafeERC20 for IERC20;

    function onReward(uint256 pid, address user, address recipient, uint256 rewardAmount, uint256 newLpAmount) external;

    function pendingTokens(uint256 pid, address user, uint256 rewardAmount) external view returns (IERC20[] memory, uint256[] memory);

    function rewardToken() external view returns (address);
}