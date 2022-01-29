// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;
import "./IRewarder.sol";

interface IMiniChefWanna {

    struct PoolInfo {
        address lpToken;
        uint allocPoint;
        uint lastRewardBlock; // actually last timestamp to be more stable
        uint accWannaPerShare;
        uint totalLp;
        address rewarder; // bonus other tokens, ex: AURORA
    }

    function rewarder(uint256 _pid) external view returns (IRewarder);
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function deposit(uint256 _pid, uint256 _amount, address _ref) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function harvest(uint256 pid, address to) external;
    function wannaPerBlock() external view returns (uint256);    
    function pendingWanna(uint256 _pid, address _user) external view returns (uint256);
}