// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface ILiquityStaking {
    function stake(uint256) external;

    function unstake(uint256) external;

    function stakes(address) external view returns (uint256);

    function getPendingETHGain(address) external view returns (uint256);

    function getPendingLUSDGain(address) external view returns (uint256);
}
