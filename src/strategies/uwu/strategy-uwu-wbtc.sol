// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./strategy-uwu-base.sol";

contract StrategyUwuWbtc is StrategyUwuBase {
    // Token addresses
    address private constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    bytes path = abi.encodePacked(weth, uint24(500), wbtc);

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyUwuBase(wbtc, path, _governance, _strategist, _controller, _timelock) {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyUwuWbtc";
    }
}
