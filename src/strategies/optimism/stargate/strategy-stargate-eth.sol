// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-stargate-base.sol";

contract StrategyStargateEthOptimism is StrategyStargateOptimismBase {
    address private _lp = 0xd22363e3762cA7339569F3d33EADe20127D5F98C;
    address private _underlying = native;
    address private _starRouter = 0xB49c4e680174E331CB0A7fF3Ab58afC9738d5F8b; //eth router
    uint256 private _lpPoolId = 0;
    uint256 private _poolId = 1;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyStargateOptimismBase(_lp, _lpPoolId, _poolId, _underlying, _starRouter, _governance, _strategist, _controller, _timelock) {
    }

    function getName() external pure override returns (string memory) {
        return "StrategyStargateEthOptimism";
    }
}
