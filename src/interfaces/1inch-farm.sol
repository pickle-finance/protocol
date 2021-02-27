// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for 1inch farming contract

interface IOneInchFarm {

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);

    function stake(uint256 amount) public;

    function withdraw(uint256 amount) public;

    function exit() external;

    function totalSupply() public view returns (uint256);
    
    function balanceOf(address account) public view returns (uint256);

    function fee() public view returns(uint256);

    function slippageFee() public view returns(uint256);

    function decayPeriod() public view returns(uint256);

    function feeVotes(address user) external view returns(uint256);

    function slippageFeeVotes(address user) external view returns(uint256);

    function decayPeriodVotes(address user) external view returns(uint256);

    function feeVote(uint256 vote) external;

    function slippageFeeVote(uint256 vote) external;

    function decayPeriodVote(uint256 vote) external;

    function discardFeeVote() external;

    function discardSlippageFeeVote() external;

    function discardDecayPeriodVote() external;

    function rescueFunds(IERC20 token, uint256 amount) external;

    function lastTimeRewardApplicable() public view returns (uint256);

    function rewardPerToken() public view returns (uint256);

    function earned(address account) public view returns (uint256);

    function getReward() public;

    function notifyRewardAmount(uint256 reward) external;

    function setRewardDistribution(address _rewardDistribution) external;
}