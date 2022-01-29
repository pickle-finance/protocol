// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

// interface for LooksRare rewards contract
interface ILookschef {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function harvest() external;

    function calculatePendingRewards(address _user)
        external
        view
        returns (uint256);

    function userInfo(address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
}
