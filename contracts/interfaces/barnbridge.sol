// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IBBStaking {
    function balanceOf(address user, address token)
        external
        view
        returns (uint256);

    function computeNewMultiplier(
        uint256 prevBalance,
        uint128 prevMultiplier,
        uint256 amount,
        uint128 currentMultiplier
    ) external pure returns (uint128);

    function currentEpochMultiplier() external view returns (uint128);

    function deposit(address tokenAddress, uint256 amount) external;

    function emergencyWithdraw(address tokenAddress) external;

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function epochIsInitialized(address token, uint128 epochId)
        external
        view
        returns (bool);

    function getCurrentEpoch() external view returns (uint128);

    function getEpochPoolSize(address tokenAddress, uint128 epochId)
        external
        view
        returns (uint256);

    function getEpochUserBalance(
        address user,
        address token,
        uint128 epochId
    ) external view returns (uint256);

    function manualEpochInit(address[] calldata tokens, uint128 epochId) external;

    function withdraw(address tokenAddress, uint256 amount) external;
}

interface IBBYieldFarm {
    function NR_OF_EPOCHS() external view returns (uint256);

    function TOTAL_DISTRIBUTED_AMOUNT() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function epochStart() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint256);

    function getEpochStake(address userAddress, uint128 epochId)
        external
        view
        returns (uint256);

    function getPoolSize(uint128 epochId) external view returns (uint256);

    function harvest(uint128 epochId) external returns (uint256);

    function lastInitializedEpoch() external view returns (uint128);

    function massHarvest() external returns (uint256);

    function userLastEpochIdHarvested() external view returns (uint256);
}
