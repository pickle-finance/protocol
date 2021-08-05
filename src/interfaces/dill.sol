// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IDill {
    function deposit_for(address, uint256) external;
    function balanceOf(address addr, uint256 timestamp) external view returns(uint256);
    function totalSupply(uint256 timestamp) external view returns(uint256);
}