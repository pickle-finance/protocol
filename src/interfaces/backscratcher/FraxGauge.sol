// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

struct LockedNFT {
    uint256 token_id; // for Uniswap V3 LPs
    uint256 liquidity;
    uint256 start_timestamp;
    uint256 ending_timestamp;
    uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    int24 tick_lower;
    int24 tick_upper;
}

struct LockedStake {
    bytes32 kek_id;
    uint256 start_timestamp;
    uint256 liquidity;
    uint256 ending_timestamp;
    uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
}

interface IFraxGaugeBase {
    function lockedLiquidityOf(address account) external view returns (uint256);

    function getReward() external returns (uint256);

    function lock_time_min() external returns (uint256);

    function combinedWeightOf(address account) external view returns (uint256);
}

interface IFraxGaugeUniV3 is IFraxGaugeBase {
    function stakeLocked(uint256 token_id, uint256 secs) external;

    function withdrawLocked(uint256 token_id) external;

    function lockedNFTsOf(address account)
        external
        view
        returns (LockedNFT[] memory);
}

interface IFraxGaugeUniV2 {
    function stakeLocked(uint256 liquidity, uint256 secs) external;

    function lockedStakesOf(address)
        external
        view
        returns (LockedStake[] memory);

    function withdrawLocked(bytes32 kek_id) external;

    function getAllRewardTokens() external view returns (address[] memory);
}
