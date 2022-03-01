// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSpookyUsdcWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 11;
    // Token addresses
    address public _lp = 0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

    // Spiritswap router
    address public _router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

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
            _router,
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
        return "StrategyLqdrSpookyUsdcWftm";
    }
}
