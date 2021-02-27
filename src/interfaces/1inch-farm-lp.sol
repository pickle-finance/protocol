// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/erc20.sol";
// interface for mooniswap; 1inch-lp token

interface IMooniswap {

    function getTokens() external view returns(IERC20[] memory tokens);

    function tokens(uint256 i) external view returns(IERC20);

    function getBalanceForAddition(IERC20 token) public view returns(uint256);

    function getBalanceForRemoval(IERC20 token) public view returns(uint256);

    function getReturn(IERC20 src, IERC20 dst, uint256 amount) external view returns(uint256);

    function deposit(uint256[2] memory maxAmounts, uint256[2] memory minAmounts) external payable returns(uint256 fairSupply, uint256[2] memory receivedAmounts);

    function depositFor(uint256[2] memory maxAmounts, uint256[2] memory minAmounts, address target) public payable nonReentrant returns(uint256 fairSupply, uint256[2] memory receivedAmounts);

    function withdraw(uint256 amount, uint256[] memory minReturns) external returns(uint256[2] memory withdrawnAmounts);

    function withdrawFor(uint256 amount, uint256[] memory minReturns, address payable target) public nonReentrant returns(uint256[2] memory withdrawnAmounts);
    function swap(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address referral) external payable returns(uint256 result);

    function swapFor(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address referral, address payable receiver) public payable nonReentrant whenNotShutdown returns(uint256 result);

    function rescueFunds(IERC20 token, uint256 amount) external;

    function fee() public view returns(uint256);

    function slippageFee() public view returns(uint256);

    function decayPeriod() public view returns(uint256);

    function virtualFee() external view returns(uint104, uint104, uint48);

    function virtualSlippageFee() external view returns(uint104, uint104, uint48);

    function virtualDecayPeriod() external view returns(uint104, uint104, uint48);

    function feeVotes(address user) external view returns(uint256);

    function slippageFeeVotes(address user) external view returns(uint256);

    function decayPeriodVotes(address user) external view returns(uint256);

    function feeVote(uint256 vote) external;

    function slippageFeeVote(uint256 vote) external;

    function decayPeriodVote(uint256 vote) external;
    function discardFeeVote() external;

    function discardSlippageFeeVote() external;

    function discardDecayPeriodVote() external;
}