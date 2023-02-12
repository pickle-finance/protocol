// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IStrategyUniV3 {
    function tick_lower() external view returns (int24);

    function tick_upper() external view returns (int24);

    function balanceProportion(int24, int24) external;

    function pool() external view returns (address);

    function timelock() external view returns (address);

    function deposit() external;

    function balanceAndDeposit(uint256 amount0Desired, uint256 amount1Desired)
        external
        returns (
            uint128 liquidity,
            uint256 unusedAmount0,
            uint256 unusedAmount1
        );

    function withdraw(address) external;

    function withdraw(uint256) external returns (uint256, uint256);

    function withdrawAll() external returns (uint256, uint256);

    function liquidityOf() external view returns (uint256);

    function harvest() external;

    function rebalance() external;

    function setTimelock(address) external;

    function setController(address _controller) external;
}
