// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

interface ILPStakingTime {
  function eToken() external view returns(address);
  function pendingEmissionToken(uint256 _pid, address _user) external view returns (uint256);
  function userInfo(uint256 pid, address user) external view returns(uint256 amount, uint256 rewardDebt);
  function deposit(uint256 _pid, uint256 _amount) external;
  function withdraw(uint256 _pid, uint256 _amount) external;
}
