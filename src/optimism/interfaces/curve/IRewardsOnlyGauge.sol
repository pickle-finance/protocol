// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7;

interface IRewardsOnlyGauge {
    function reward_contract() external view returns (address);

    function balanceOf(address _owner) external view returns (uint256);

    function claim_rewards(address user) external;

    function claimable_reward(address _addr, address _token) external view returns (uint256);

    function claimable_reward_write(address _addr, address _token) external returns (uint256);

    function deposit(uint256 _value) external;

    function withdraw(uint256 _value) external;
}
