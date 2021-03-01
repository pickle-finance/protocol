// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/erc20.sol";
// interface for mooniswap; 1inch-lp token

interface IMooniswap {

    function getReturn(IERC20 src, IERC20 dst, uint256 amount) external view returns(uint256);

    function deposit(uint256[2] calldata maxAmounts, uint256[2] calldata minAmounts) external payable returns(uint256 fairSupply, uint256[2] memory receivedAmounts);

    // function withdraw(uint256 amount, uint256[] memory minReturns) external returns(uint256[2] memory withdrawnAmounts);

    function swap(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address referral) external payable returns(uint256 result);

}