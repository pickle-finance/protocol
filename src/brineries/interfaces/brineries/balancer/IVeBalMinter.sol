// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IVEBalMinter {

    function deposit(uint256 _amount) external;

    function earn() external;
}
