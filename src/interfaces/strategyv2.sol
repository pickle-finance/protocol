// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IStrategyV2 {

    function tick_lower() external view returns (int24);

    function tick_upper() external view returns (int24);

    function pool() external view returns (address);

    function timelock() external view returns (address);

    function deposit() external;

    function withdraw(address) external;

    function withdraw(uint256) external returns (uint256, uint256);

    function withdrawAll() external returns (uint256, uint256);

    function liquidityOf() external view returns (uint256);

    function harvest() external;

    function setTimelock(address) external;

    function setController(address _controller) external;
}
