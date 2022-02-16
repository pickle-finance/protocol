// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSushiWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 13;
    // Token addresses
    address public _lp = 0xf84E313B36E86315af7a06ff26C8b20e9EB443C3;
    address public sushi = 0xf84E313B36E86315af7a06ff26C8b20e9EB443C3;

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
        swapRoutes[sushi] = [wftm, sushi];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrSushiWftm";
    }
}
