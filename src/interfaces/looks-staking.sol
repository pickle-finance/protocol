pragma solidity ^0.6.7;

interface ILooksStaking {
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256);

    function calculateSharePriceInLOOKS() external view returns (uint256);

    function calculateSharesValueInLOOKS(address user)
        external
        view
        returns (uint256);

    function deposit(uint256 amount, bool claimRewardToken) external;

    function harvest() external;

    function userInfo(address)
        external
        view
        returns (
            uint256 shares,
            uint256 userRewardPerTokenPaid,
            uint256 rewards
        );

    function totalShares() external view returns (uint256);

    function withdraw(uint256 shares, bool claimRewardToken) external;

    function withdrawAll(bool claimRewardToken) external;
}

interface ILooksDistributor {
    function userInfo(address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
}
