// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-uwu-base.sol";

contract StrategyUwuWeth is StrategyUwuBase {
    bytes path = "";

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyUwuBase(weth, path, _governance, _strategist, _controller, _timelock) {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUwuWeth";
    }
}
