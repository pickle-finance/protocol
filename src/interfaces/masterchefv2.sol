// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for Sushiswap MasterChef contract
interface IMasterchefV2 {
    function MASTER_PID() external view returns (uint256);

    function MASTER_CHEF() external view returns (address);

    function rewarder(uint256 pid) external view returns (address);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function sushiPerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            uint256 lastRewardBlock,
            uint256 accsushiPerShare,
            uint256 allocPoint
        );

    function poolLength() external view returns (uint256);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function harvestFromMasterChef() external;

    function harvest(uint256 pid, address to) external;

    function totalAllocPoint() external view returns (uint256);

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;
}