// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-convex-farm-base.sol";

contract StrategyConvexEthLp is StrategyConvexFarmBase {

    uint256 public convex_poolId = 1;

    address public sushi_convex_eth_lp = 0x05767d9EF41dC40689678fFca0608878fb3dE906;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            convex_poolId,
            sushi_convex_eth_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyConvexEthLp";
    }
}