// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IJar {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}