// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-beetx-base.sol";

contract StrategyBeetxIbRethLp is StrategyBeetxBase {
    bytes32 private _vaultPoolId = 0x785f08fb77ec934c01736e30546f87b4daccbe50000200000000000000000041;
    address private _lp = 0x785F08fB77ec934c01736E30546f87B4daccBe50;
    address private _gauge = 0x1C438149E3e210233FCE91eeE1c097d34Fd655c2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBeetxBase(_vaultPoolId, _gauge, _lp, _governance, _strategist, _controller, _timelock) {
        // Pool IDs
        bytes32 ethReth = 0x4fd63966879300cafafbb35d157dc5229278ed2300020000000000000000002b;
        bytes32 ethIb = 0xefb0d9f51efd52d7589a9083a6d0ca4de416c24900020000000000000000002c;

        // Tokens addresses
        address ib = 0x00a35FD824c717879BF370E70AC6868b95870Dfb;
        address reth = 0x9Bcef72be871e61ED4fBbc7630889beE758eb81D;

        // Rewards toNativeRoutes (Need a valid route for every reward token) //
        // IB->ETH
        // ETH-IB
        bytes32[] memory _ibToNativePoolIds = new bytes32[](1);
        _ibToNativePoolIds[0] = ethIb;
        address[] memory _ibToNativeTokenPath = new address[](2);
        _ibToNativeTokenPath[0] = ib;
        _ibToNativeTokenPath[1] = native;
        _addToNativeRoute(_ibToNativePoolIds, _ibToNativeTokenPath);

        // Pool tokens toTokenRoutes (Only need one token route) //
        // ETH->RETH
        // ETH-RETH
        bytes32[] memory _toRethPoolIds = new bytes32[](1);
        _toRethPoolIds[0] = ethReth;
        address[] memory _toRethTokenPath = new address[](2);
        _toRethTokenPath[0] = native;
        _toRethTokenPath[1] = reth;
        _addToTokenRoute(_toRethPoolIds, _toRethTokenPath);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyBeetxIbRethLp";
    }
}
