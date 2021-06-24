// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../lib/erc20.sol";

interface IYearnVault is IERC20 {
    function token() external view returns (address);

    function depositAll() external;

    function deposit(uint256) external;

    function withdrawAll() external;

    function withdraw(uint256) external;

    function earn() external;

    function decimals() external view returns (uint8);

    function balance() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
}
