// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-stargate-base.sol";

contract StrategyStargateUsdcOptimism is StrategyStargateOptimismBase {
    address private _lp = 0xDecC0c09c3B5f6e92EF4184125D5648a66E35298;
    address private _underlying = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607; //usdc
    address private _starRouter = 0xB0D502E938ed5f4df2E681fE6E419ff29631d62b; //usdc router
    uint256 private _lpPoolId = 1;
    uint256 private _poolId = 0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyStargateOptimismBase(_lp, _lpPoolId, _poolId, _underlying, _starRouter, _governance, _strategist, _controller, _timelock) {
        // underlying route
        ISolidlyRouter.route[] memory _toUsdc = new ISolidlyRouter.route[](1);
        _toUsdc[0] = ISolidlyRouter.route(native, _underlying, false);
        _addToTokenRoute(_toUsdc);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyStargateUsdcOptimism";
    }
}
