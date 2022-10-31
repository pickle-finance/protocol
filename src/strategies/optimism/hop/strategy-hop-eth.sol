// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-hop-base.sol";

contract StrategyHopEthOptimism is StrategyHopOptimismBase {
    address private _staking = 0x95d6A95BECfd98a7032Ed0c7d950ff6e0Fa8d697;
    address private _underlying = weth;
    address private _lp = 0x5C2048094bAaDe483D0b1DA85c3Da6200A88a849; // hop eth lp
    address private _pool = 0xaa30D6bba6285d0585722e2440Ff89E23EF68864;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyHopOptimismBase(_lp, _staking, _underlying, _pool, _governance, _strategist, _controller, _timelock) {}

    function getName() external pure override returns (string memory) {
        return "StrategyHopEthOptimism";
    }
}
