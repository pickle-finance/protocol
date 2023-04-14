// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-uwu-base.sol";

contract StrategyUwuDai is StrategyUwuBase {
    // Token addresses
    address private constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bytes path = abi.encodePacked(weth, uint24(500), dai);

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyUwuBase(dai, path, _governance, _strategist, _controller, _timelock) {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUwuDai";
    }
}
