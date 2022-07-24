// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface ISwaprRewarder {
    function rewards() external view returns (address);

    function claimableRewards(address) external view returns (uint256[] memory);

    function stake(uint256) external;

    function withdraw(uint256) external;

    function claimAll(address) external;

    function stakedTokensOf(address) external view returns (uint256);

    function getRewardTokens() external view returns (address[] memory);
}
