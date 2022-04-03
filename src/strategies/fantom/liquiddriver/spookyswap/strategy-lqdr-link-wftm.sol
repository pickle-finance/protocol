// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrLinkWftm is StrategyLqdrFarmLPBase {
    uint256 public _poolId = 14;
    // Token addresses
    address public _lp = 0x89d9bC2F2d091CfBFc31e333D6Dc555dDBc2fd29;
    address public link = 0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8;

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
        swapRoutes[link] = [wftm, link];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrLinkWftm";
    }
}
