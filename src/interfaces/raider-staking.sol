// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IRaiderStaking {
    function addressStakedBalance(address account) external view returns (uint256);

    function userPendingRewards(address account) external view returns (uint256);

    function getRewards() external;

    function createStake(uint256 amount) external;

    function removeStake(uint256 amount) external;
}