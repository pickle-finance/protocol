pragma solidity ^0.6.0;

interface Hevm {
    function warp(uint256) external;
    function store(address c, bytes32 loc, bytes32 val) external;
}