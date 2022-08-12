// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface ITestERC20 {
    function mintToken(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}
