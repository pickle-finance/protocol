// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IUwuRewards {
    function claim(address _user, address[] calldata _tokens) external;

    function claimableReward(address _user, address[] calldata _tokens) external view returns (uint256[] memory);
}

interface IUwuLocker {
    function exitEarly(address) external;
}
