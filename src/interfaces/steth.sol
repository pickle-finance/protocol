// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../lib/erc20.sol";

interface IStEth is IERC20 {
    function submit(address) external payable returns (uint256);
}