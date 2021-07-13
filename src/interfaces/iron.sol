// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IIronchef {
    function pendingReward(uint256 _pid, address _user) external view returns (uint256 pending);

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function deposit(uint256 pid, uint256 amount, address to) public;

    function withdraw(uint256 pid, uint256 amount, address to) public ;
}

interface IIronSwap {
    function addLiquidity(
        uint256[] memory amounts,
        uint256 minMintAmount,
        uint256 deadline
    ) external  returns (uint256)
}