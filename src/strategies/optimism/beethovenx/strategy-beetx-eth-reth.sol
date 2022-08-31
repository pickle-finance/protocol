// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-beetx-base.sol";

contract StrategyBeetxEthRethLp is StrategyBeetxBase {
    bytes32 private _vaultPoolId = 0x4fd63966879300cafafbb35d157dc5229278ed2300020000000000000000002b;
    address private _lp = 0x4Fd63966879300caFafBB35D157dC5229278Ed23;
    address private _gauge = 0x38f79beFfC211c6c439b0A3d10A0A673EE63AFb4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyBeetxBase(_vaultPoolId, _gauge, _lp, _governance, _strategist, _controller, _timelock) {
        // Pool IDs
        bytes32 beetsBalOp = 0xd6e5824b54f64ce6f1161210bc17eebffc77e031000100000000000000000006;
        bytes32 ethOpUsdc = 0x39965c9dab5448482cf7e002f583c812ceb53046000100000000000000000003;

        // Rewards toNativeRoutes (Need a valid route for every reward token) //
        // BAL->ETH
        // BEETS-BAL-OP => ETH-OP-USDC
        bytes32[] memory _balToNativePoolIds = new bytes32[](2);
        _balToNativePoolIds[0] = beetsBalOp;
        _balToNativePoolIds[1] = ethOpUsdc;
        address[] memory _balToNativeTokenPath = new address[](3);
        _balToNativeTokenPath[0] = bal;
        _balToNativeTokenPath[1] = op;
        _balToNativeTokenPath[2] = native;
        _addToNativeRoute(_balToNativePoolIds, _balToNativeTokenPath);

        // BEETS->ETH
        // BEETS-BAL-OP => ETH-OP-USDC
        bytes32[] memory _beetsToNativePoolIds = new bytes32[](2);
        _beetsToNativePoolIds[0] = beetsBalOp;
        _beetsToNativePoolIds[1] = ethOpUsdc;
        address[] memory _beetsToNativeTokenPath = new address[](3);
        _beetsToNativeTokenPath[0] = beets;
        _beetsToNativeTokenPath[1] = op;
        _beetsToNativeTokenPath[2] = native;
        _addToNativeRoute(_beetsToNativePoolIds, _beetsToNativeTokenPath);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyBeetxEthRethLp";
    }
}
