// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrDeiUsdc is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 36;
    // Token addresses
    address public _lp = 0x8eFD36aA4Afa9F4E157bec759F1744A7FeBaEA0e;
    address public dei = 0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

    // Spiritswap router
    address public router = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyLqdrFarmLPBase(
            _lp,
            _poolId,
            router,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[dei] = [wftm, usdc, dei];
        swapRoutes[usdc] = [wftm, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrDeiUsdc";
    }
}
