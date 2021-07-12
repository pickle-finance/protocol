pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

struct LockedStake {
    bytes32 kek_id;
    uint256 start_timestamp;
    uint256 liquidity;
    uint256 end_timestmap;
    uint256 lock_multiplier;
}

interface SwapFlashLoan {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external;
}

interface ICommunalFarm {
    function earned(address) external view returns (uint256[] memory);

    function getAllRewardTokens() external view returns (address[] memory);

    function getRewardForDuration() external view returns (uint256[] memory);

    function lockedLiquidityOf(address) external view returns (uint256);

    function lockedStakesOf(address)
        external
        view
        returns (LockedStake[] memory);

    function rewardRates(uint256) external view returns (uint256);

    function rewardSymbols(uint256) external view returns (string memory);

    function rewardTokens(uint256) external view returns (address);

    function rewardsDuration() external view returns (uint256);

    function rewardsPerToken() external view returns (uint256[] memory);

    function stakesUnlocked() external view returns (bool);

    function totalLiquidityLocked() external view returns (uint256);

    function combinedWeightOf(address) external view returns (uint256);

    function calcCurCombinedWeight(address)
        external
        view
        returns (uint256, uint256);

    function lock_time_min() external view returns (uint256);

    function lockMultiplier(uint256) external view returns (uint256);

    function lock_max_multiplier() external view returns (uint256);

    function getReward() external;

    function stakeLocked(uint256, uint256) external;

    function sync() external;

    function toggleRewardsCollection() external;

    function toggleStaking() external;

    function toggleWithdrawals() external;

    function unlockStakes() external;

    function withdrawLocked(bytes32) external;
}
