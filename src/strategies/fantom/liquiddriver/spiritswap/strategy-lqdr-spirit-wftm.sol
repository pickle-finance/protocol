// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSpiritWftm is StrategyLqdrFarmLPBase {
    uint256 public spirit_ftm_poolId = 28;
    // Token addresses
    address public spirit_ftm_lp = 0x30748322B6E34545DBe0788C421886AEB5297789;
    address public spirit = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;

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
            spirit_ftm_lp,
            spirit_ftm_poolId,
            router,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[spirit] = [wftm, spirit];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrSpiritWftm";
    }
}
