// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for Alchemix farm contract
import "../lib/erc20.sol";

interface IStakingPools {    
    function createPool(
        IERC20 _token
    ) external returns (uint256);
    function setRewardWeights(uint256[] calldata _rewardWeights) external;
    function acceptGovernance() external;
    function setPendingGovernance(address _pendingGovernance) external;
    function setRewardRate(uint256 _rewardRate) external;
    function deposit(uint256 _poolId, uint256 _depositAmount) external;
    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
    function claim(uint256 _poolId) external;
    function exit(uint256 _poolId) external;
    function rewardRate() external view returns (uint256);
    function totalRewardWeight() external view returns (uint256);
    function poolCount() external view returns (uint256);
    function getPoolToken(uint256 _poolId) external view returns (IERC20);
    function getPoolTotalDeposited(uint256 _poolId) external view returns (uint256);
    function getPoolRewardWeight(uint256 _poolId) external view returns (uint256);
    function getPoolRewardRate(uint256 _poolId) external view returns (uint256);
    function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256);
    function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256);
}
