// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IIronchef {
    function pendingReward(uint256 _pid, address _user) external view returns (uint256 pending);

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function deposit(uint256 pid, uint256 amount, address to) external;

    function withdraw(uint256 pid, uint256 amount, address to) external;
    
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external; 

    function harvest(uint256 pid, address to) external;
}

interface IIronSwap {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minMintAmount,
        uint256 deadline
    ) external returns (uint256);
}