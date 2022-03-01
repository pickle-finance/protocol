// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrDaiWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 12;
    // Token addresses
    address public _lp = 0xe120ffBDA0d14f3Bb6d6053E90E63c572A66a428;
    address public dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;

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
        swapRoutes[dai] = [wftm, dai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrDaiWftm";
    }
}
