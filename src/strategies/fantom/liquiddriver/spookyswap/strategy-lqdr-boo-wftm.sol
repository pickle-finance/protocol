// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrBooWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 10;
    // Token addresses
    address public _lp = 0xEc7178F4C41f346b2721907F5cF7628E388A7a58;
    address public boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;

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
        swapRoutes[boo] = [wftm, boo];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrBooWftm";
    }
}
