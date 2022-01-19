// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;


// interface for Platypus contract
interface IPlatypusPools {

    /* Writes */

    function deposit(
        address want,
        uint256 amount,
        address depositor,
        uint256 deadline
    ) external;

}