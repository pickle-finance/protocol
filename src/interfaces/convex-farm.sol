// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/erc20.sol";

interface IConvexBooster {
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function deposit(
        uint256,
        uint256,
        bool
    ) external returns (bool);

    function depositAll(uint256, bool) external returns (bool);

    function withdraw(uint256, uint256) external returns (bool);

    function withdrawAll(uint256) external returns (bool);

    function rewardClaimed(
        uint256,
        address,
        uint256
    ) external returns (bool);
}

interface IBaseRewardPool {
    function getReward(address, bool) external returns (bool);

    function getReward() external returns (bool);

    function earned(address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function withdrawAndUnwrap(uint256, bool) external returns (bool);
}

interface IVirtualBalanceRewardPool {
    function getReward(address) external;

    function getReward() external;

    function balanceOf(address) external view returns (uint256);

    function earned(address) external view returns (uint256);
}

interface IConvexToken is IERC20 {
    function reductionPerCliff() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}
