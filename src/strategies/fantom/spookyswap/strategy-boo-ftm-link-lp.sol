// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-spookyswap-base.sol";

contract StrategyBooFtmLinkLp is StrategyBooFarmLPBase {
    uint256 public wftm_link_poolid = 6;
    // Token addresses
    address public wftm_link_lp = 0x89d9bC2F2d091CfBFc31e333D6Dc555dDBc2fd29;
    address public link = 0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBooFarmLPBase(
            wftm_link_lp,
            wftm_link_poolid,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[link] = [boo, wftm, link];
        swapRoutes[wftm] = [boo, wftm];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBooFtmLinkLp";
    }
}
