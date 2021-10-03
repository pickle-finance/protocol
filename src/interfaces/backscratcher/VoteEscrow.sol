// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface VoteEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function locked__end(address) external view returns (uint256);

    function withdraw() external;
}
