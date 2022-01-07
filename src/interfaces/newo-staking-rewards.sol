pragma solidity ^0.6.7;

interface INewoStakingRewards {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}
