// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface ISolidlyGauge {
    function earned(address token, address account) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function deposit(uint256 amount, uint256 tokenId) external;

    function withdraw(uint256 amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);
}
