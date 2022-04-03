// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../../strategy-lqdr-base.sol";

contract StrategyLqdrSpiritWethWftm is StrategyLqdrFarmLPBase {
    uint256 public weth_ftm_poolId = 6;
    // Token addresses
    address public weth_ftm_lp = 0x613BF4E46b4817015c01c6Bb31C7ae9edAadc26e;
    address public weth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;

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
            weth_ftm_lp,
            weth_ftm_poolId,
            router,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[weth] = [wftm, weth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyLqdrSpiritWethWftm";
    }
}
