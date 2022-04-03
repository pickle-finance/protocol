// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSpiritUsdcWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 5;
    // Token addresses
    address public _lp = 0xe7E90f5a767406efF87Fdad7EB07ef407922EC1D;
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
        swapRoutes[usdc] = [wftm, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrSpiritUsdcWftm";
    }
}
