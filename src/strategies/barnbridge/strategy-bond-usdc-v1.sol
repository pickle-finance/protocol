// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/barnbridge.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-bond-farm-base.sol";

contract StrategyBondUsdcV1 is StrategyBondFarmBase {
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // **** Constructor **** //
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBondFarmBase(
            usdc,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** View methods ****

    function getName() external override pure returns (string memory) {
        return "StrategyBondUsdcV1";
    }
}
