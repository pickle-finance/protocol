// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IStrategyConverter {
    function convert(
        address _refundExcess, // address to send the excess amount when adding liquidity
        address _fromWant,
        address _toWant,
        uint256 _wantAmount
    ) external returns (uint256);
}
