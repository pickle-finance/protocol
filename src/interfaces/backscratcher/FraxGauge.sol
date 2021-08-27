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

interface FraxGauge {
    function stakeLocked(uint256 token_id, uint256 secs) external;

    function lockedLiquidityOf(address account) external view returns (uint256);

    function withdrawLocked(uint256 token_id) external;

    function lockedNFTsOf(address account)
        external
        view
        returns (LockedNFT[] memory);

    function combinedWeightOf(address account) external view returns (uint256);

    function getReward() external returns (uint256);

    function lock_time_min() external returns (uint256);
}
