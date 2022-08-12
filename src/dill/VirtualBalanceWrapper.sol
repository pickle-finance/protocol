// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IJar.sol";

contract VirtualBalanceWrapper {
    IJar public jar;

    function totalSupply() public view returns (uint256) {
        return jar.totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        return jar.balanceOf(account);
    }
}