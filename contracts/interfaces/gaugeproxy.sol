// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

interface IGaugeV2 {
    function depositAll() external;

    function deposit(uint256 amount) external;

    function depositFor(uint256 amount, address account) external;

    function withdrawAll() external;

    function withdraw(uint256 amount) external;

    function exit() external;

    function getReward() external;
}

interface IGaugeProxyV2 {
    function tokens() external view returns (address[] memory);

    function getGauge(address _token) external view returns (address);
}