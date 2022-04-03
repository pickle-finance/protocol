// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlAvaxNearLp is StrategyBrlFarmBase {
    uint256 public avax_near_poolid = 11;
    // Token addresses
    address public avax_near_lp = 0x8F6e13B3D28B09535EB82BE539c1E4802B0c25B7;
    address public avax = 0x80A16016cC4A2E6a2CACA8a4a498b1699fF0f844;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            avax,
            near,
            avax_near_poolid,
            avax_near_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[avax] = [brl, near, avax];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlAvaxNearLp";
    }
}
