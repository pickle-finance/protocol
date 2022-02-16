// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrWftm is StrategyLqdrFarmLPBase {
    uint256 public lqdr_ftm_poolId = 0;
    // Token addresses
    address public lqdr_ftm_lp = 0x4Fe6f19031239F105F753D1DF8A0d24857D0cAA2;
    
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
            lqdr_ftm_lp,
            lqdr_ftm_poolId,
            router,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[lqdr] = [wftm, lqdr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrWftm";
    }
}
