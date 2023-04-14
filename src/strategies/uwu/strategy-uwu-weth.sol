// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-uwu-base.sol";

contract StrategyUwuWeth is StrategyUwuBase {
    address private constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
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
