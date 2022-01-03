// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

interface IDodoMine {
    function getPendingRewardByToken(address user, address rewardToken)
        external
        view
        returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function claimAllRewards() external;
}

interface IDodoPool { 
    function _QUOTE_TOKEN_() external view returns (address);
}

interface IDodoSwap {
    function dodoSwapV1(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] calldata dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] calldata dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function addDVMLiquidity(
        address dvmAddress,
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint8 flag,
        uint256 deadLine
    )
        external
        returns (
            uint256 shares,
            uint256 baseAdjustedInAmount,
            uint256 quoteAdjustedInAmount
        );
}

interface IDodoMultiSwap {
    function mixSwap(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] calldata mixAdapters,
        address[] calldata mixPairs,
        address[] calldata assetTo,
        uint256 directions,
        bytes[] calldata moreInfos,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}
