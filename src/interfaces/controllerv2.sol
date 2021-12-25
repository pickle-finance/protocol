// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IControllerV2 {
    function jars(address) external view returns (address);

    function devfund() external view returns (address);

    function treasury() external view returns (address);

    function liquidityOf(address) external view returns (uint256);

    function withdraw(address, uint256) external returns (uint256, uint256);

    function earn(
        address,
        uint256,
        uint256
    ) external;

    function strategies(address) external view returns (address);

    function balanceProportion(address,int24,int24) external;

    function getUpperTick(address) external view returns (int24);

    function getLowerTick(address) external view returns (int24);
}
