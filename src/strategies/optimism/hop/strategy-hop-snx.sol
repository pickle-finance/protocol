// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-hop-base.sol";

contract StrategyHopSnxOptimism is StrategyHopOptimismBase {
    address private _staking = 0x25a5A48C35e75BD2EFf53D94f0BB60d5A00E36ea;
    address private _underlying = 0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4; //snx
    address private _usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address private _lp = 0xe63337211DdE2569C348D9B3A0acb5637CFa8aB3; // hop snx lp
    address private _pool = 0x1990BC6dfe2ef605Bfc08f5A23564dB75642Ad73;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyHopOptimismBase(_lp, _staking, _underlying, _pool, _governance, _strategist, _controller, _timelock) {
        // underlying route
        ISolidlyRouter.route[] memory _toSnx = new ISolidlyRouter.route[](2);
        _toSnx[0] = ISolidlyRouter.route(native, _usdc, false);
        _toSnx[1] = ISolidlyRouter.route(_usdc, _underlying, false);
        _addToTokenRoute(_toSnx);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyHopSnxOptimism";
    }
}
