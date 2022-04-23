// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITempleRouter {
    function swapExactTempleForFrax(
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function swapExactFraxForTemple(
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}
