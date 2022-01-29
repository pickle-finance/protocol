// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-brl-base.sol";

contract StrategyBrlNearEthLp is StrategyBrlFarmBase {
    uint256 public near_eth_poolid = 1;
    // Token addresses
    address public near_eth_lp = 0xc57eCc341aE4df32442Cf80F34f41Dc1782fE067;
    address public eth = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBrlFarmBase(
            near,
            eth,
            near_eth_poolid,
            near_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[near] = [brl, near];
        swapRoutes[eth] = [brl, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyBrlNearEthLp";
    }
}
