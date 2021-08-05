// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for Sushiswap MasterChef contract
interface IAlcxRewarder {
    function pendingToken(uint256 pid, address user)
        external
        view
        returns (uint256);
}
