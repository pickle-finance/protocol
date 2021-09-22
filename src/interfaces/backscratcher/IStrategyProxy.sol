// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;
import "./FraxGauge.sol";

interface IStrategyProxy {
    function withdrawV3(
        address _gauge,
        uint256 _tokenId,
        address[] calldata _rewardTokens
    ) external returns (uint256);

    function withdrawV2(
        address _gauge,
        address _token,
        bytes32 _kek_id,
        address[] calldata _rewardTokens
    ) external returns (uint256);

    function balanceOf(address _gauge) external view returns (uint256);

    function lockedNFTsOf(address _gauge) external view returns (LockedNFT[] memory);

    function lockedStakesOf(address _gauge) external view returns (LockedStake[] memory);

    function withdrawAllV3(
        address _gauge,
        address _token,
        address[] calldata _rewardTokens
    ) external returns (uint256 amount);

    function withdrawAllV2(
        address _gauge,
        address _token,
        address[] calldata _rewardTokens
    ) external returns (uint256 amount);

    function harvest(address _gauge, address[] calldata _tokens) external;

    function depositV2(
        address _gauge,
        address _token,
        uint256 _secs
    ) external;

    function depositV3(
        address _gauge,
        uint256 _tokenId,
        uint256 _secs
    ) external;

    function claim(address recipient) external;

    function lock() external;

    function claimRewards(address _gauge, address _token) external;
}
