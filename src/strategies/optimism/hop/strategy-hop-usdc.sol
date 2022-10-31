// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-hop-base.sol";

contract StrategyHopUsdcOptimism is StrategyHopOptimismBase {
    address private _staking = 0xf587B9309c603feEdf0445aF4D3B21300989e93a;
    address private _underlying = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607; //usdc
    address private _lp = 0x2e17b8193566345a2Dd467183526dEdc42d2d5A8; // hop usdc lp
    address private _pool = 0x3c0FFAca566fCcfD9Cc95139FEF6CBA143795963;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyHopOptimismBase(_lp, _staking, _underlying, _pool, _governance, _strategist, _controller, _timelock) {
        // underlying route
        ISolidlyRouter.route[] memory _toUsdc = new ISolidlyRouter.route[](1);
        _toUsdc[0] = ISolidlyRouter.route(native, _underlying, false);
        _addToTokenRoute(_toUsdc);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyHopUsdcOptimism";
    }
}
