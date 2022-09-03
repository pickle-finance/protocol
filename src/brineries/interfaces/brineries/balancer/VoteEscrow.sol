// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;//^0.6.7

interface VoteEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256) external;

    function locked__end(address) external view returns (uint256);

    function withdraw() external;

    function balanceOf(address) external view returns (uint256);
}
