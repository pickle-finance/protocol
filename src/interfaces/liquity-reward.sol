// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface ILiquityFarmReward {
  function balanceOf(address account) external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function exit() external;

  function claimReward() external;

  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;
}
