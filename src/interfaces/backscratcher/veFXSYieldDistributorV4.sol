// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface veFXSYieldDistributorV4 {
    function checkpoint() external;

    function notifyRewardAmount(uint256) external;

    function toggleRewardNotifier(address) external;

    function sync() external;
}
