// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/erc20.sol";

// interface for Axial Rewarder contract
interface IPlatypusRewarder {
    using SafeERC20 for IERC20;

    function onPlatypusReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user)
        external
        view
        returns (uint256 pending);

    function rewardToken() external view returns (address);
}