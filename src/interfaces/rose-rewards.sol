// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

interface IRoseRewards {
    struct Reward {
        address rewardsDistributor;
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    function stake(uint256 amount) external;

    function earned(address account, address _rewardsToken)
        external
        view
        returns (uint256);

    function getReward() external;

    function exit() external;

    function balanceOf(address account) external view returns (uint256);

    function withdraw(uint256 amount) external;

    function rewards(address account, address token)
        external
        view
        returns (uint256);

    function rewardTokens() external view returns (address[] memory);

    function rewardData(address token) external view returns (Reward memory);
}
