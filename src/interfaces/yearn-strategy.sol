// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.7;

import "../lib/yearn-affiliate-wrapper.sol";

interface IYearnStrategy {
    function want() external view returns (address);

    function timelock() external view returns (address);

    function balanceOfWant() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function getName() external returns (string memory);

    function setGovernance(address _governance) external;

    function setController(address _controller) external;

    function deposit() external;

    function withdraw(IERC20 _asset) external returns (uint256 balance);

    function withdraw(uint256 _amount) external;

    function withdrawForSwap(uint256 _amount)
        external
        returns (uint256 balance);

    function withdrawAll() external returns (uint256 balance);

    function execute(address _target, bytes calldata _data)
        external
        payable
        returns (bytes memory response);

    function execute(bytes calldata _data)
        external
        payable
        returns (bytes memory response);

    function migrate() external returns (uint256);

    function migrate(uint256 amount) external returns (uint256);

    function migrate(uint256 amount, uint256 maxMigrationLoss)
        external
        returns (uint256);

    function setRegistry(address _registry) external;

    function bestVault() external virtual view returns (VaultAPI);

    function allVaults() external virtual view returns (VaultAPI[] memory);

    function totalVaultBalance(address account)
        external
        view
        returns (uint256 balance);

    function totalAssets() external view returns (uint256 assets);
}
