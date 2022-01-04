// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

import "./IRewarder.sol";

interface IMiniChefBrl {
    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock; 
        uint256 accBRLPerShare;
        uint256 depositFeeBP;
    }

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function harvest(uint256 pid, address to) external;

    function brlPerBlock() external view returns (uint256);

    function pendingBRL(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}
