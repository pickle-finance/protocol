// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../lib/erc20.sol";

interface IJarV2 is IERC20 {
    function pool() external view returns (address);

    function tick_lower() external view returns (address);

    function tick_upper() external view returns (address);

    function getRatio() external view returns (uint256);

    function depositAll() external;

    function balance() external view returns (uint256);

    function deposit(uint256, uint256) external;

    function withdrawAll() external;

    function withdraw(uint256) external;

    function earn() external;

    function decimals() external view returns (uint8);
}
