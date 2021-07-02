// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/erc20.sol";

// interface for MasterChefv2 Rewarder contract
interface IMasterChefv2Rewarder {
    function pendingTokens(
        uint256 pid,
        address user,
        uint256 sushiAmount
    ) external view returns (IERC20[] memory, uint256[] memory);
}