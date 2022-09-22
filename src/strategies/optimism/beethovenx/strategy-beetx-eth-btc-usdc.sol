// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-beetx-base.sol";

contract StrategyBeetxEthBtcUsdcLp is StrategyBeetxBase {
    bytes32 private _vaultPoolId = 0x5028497af0c9a54ea8c6d42a054c0341b9fc6168000100000000000000000004;
    address private _lp = 0x5028497af0c9a54ea8C6D42a054c0341B9fc6168;
    address private _gauge = 0x2D6743160AB3038aF12C6a6B605C683bc9e4f0B6;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBeetxBase(_vaultPoolId, _gauge, _lp, _governance, _strategist, _controller, _timelock) {
        // Pool IDs
        bytes32 beetsBalOp = 0xd6e5824b54f64ce6f1161210bc17eebffc77e031000100000000000000000006;
        bytes32 ethOpUsdc = 0x39965c9dab5448482cf7e002f583c812ceb53046000100000000000000000003;
        bytes32 qiEthOp = 0x40dbe796eae37e371cf0217a6dbb946cdaf9f1b7000100000000000000000026;

        // Tokens addresses
        address qi = 0x3F56e0c36d275367b8C502090EDF38289b3dEa0d;

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

        // QI->ETH
        // QI-ETH-OP-USDC
        bytes32[] memory _qiToNativePoolIds = new bytes32[](1);
        _qiToNativePoolIds[0] = qiEthOp;
        address[] memory _qiToNativeTokenPath = new address[](2);
        _qiToNativeTokenPath[0] = qi;
        _qiToNativeTokenPath[1] = native;
        _addToNativeRoute(_qiToNativePoolIds, _qiToNativeTokenPath);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyBeetxEthBtcUsdcLp";
    }
}
