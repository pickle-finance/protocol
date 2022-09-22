// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-beetx-base.sol";

contract StrategyBeetxEthIbLp is StrategyBeetxBase {
    bytes32 private _vaultPoolId = 0xefb0d9f51efd52d7589a9083a6d0ca4de416c24900020000000000000000002c;
    address private _lp = 0xeFb0D9F51EFd52d7589A9083A6d0CA4de416c249;
    address private _gauge = 0x3672884a609bFBb008ad9252A544F52dF6451A03;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBeetxBase(_vaultPoolId, _gauge, _lp, _governance, _strategist, _controller, _timelock) {
        // Pool IDs
        bytes32 beetsBalOp = 0xd6e5824b54f64ce6f1161210bc17eebffc77e031000100000000000000000006;
        bytes32 ethOpUsdc = 0x39965c9dab5448482cf7e002f583c812ceb53046000100000000000000000003;
        bytes32 ethIb = _vaultPoolId;

        // Tokens addresses
        address ib = 0x00a35FD824c717879BF370E70AC6868b95870Dfb;

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

        // IB->ETH
        // IB-ETH-OP-USDC
        bytes32[] memory _ibToNativePoolIds = new bytes32[](1);
        _ibToNativePoolIds[0] = ethIb;
        address[] memory _ibToNativeTokenPath = new address[](2);
        _ibToNativeTokenPath[0] = ib;
        _ibToNativeTokenPath[1] = native;
        _addToNativeRoute(_ibToNativePoolIds, _ibToNativeTokenPath);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyBeetxEthIbLp";
    }
}
