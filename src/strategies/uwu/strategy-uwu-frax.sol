// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-uwu-base.sol";

contract StrategyUwuFrax is StrategyUwuBase {
    // Token addresses
    address private constant frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address private constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    bytes path = abi.encodePacked(weth, uint24(500), usdc, uint24(500), frax);

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyUwuBase(frax, path, _governance, _strategist, _controller, _timelock) {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUwuFrax";
    }
}
