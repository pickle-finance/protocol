// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

import "./IRewarder.sol";

interface IMasterChefBrl {
    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock; // actually last timestamp to be more stable
        uint256 accBrlPerShare;
        uint256 totalLp;
        address rewarder; // bonus other tokens, ex: AURORA
    }

    function rewarder(uint256 _pid) external view returns (IRewarder);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _ref
    ) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function harvest(uint256 pid, address to) external;

    function brlPerBlock() external view returns (uint256);

    function pendingBrl(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}
