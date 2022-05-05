// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IAurigamiRewarder {
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256[] memory rewards);

    function getUserInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        );

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function harvest(
        address _user,
        uint256 _pid,
        uint256 _max
    ) external;
}

interface IAurigamiController {
    function claimReward(uint8, address) external;
}
