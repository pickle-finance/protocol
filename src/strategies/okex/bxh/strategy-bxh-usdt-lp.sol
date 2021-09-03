
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-bxh-farm-base.sol";

contract StrategyBxhUsdtLp is StrategyBxhFarmBase {
    uint256 public bxh_usdt_poolId = 12;

    // Token addresses
    address public bxh_usdt_lp = 0x04b2C23Ca7e29B71fd17655eb9Bd79953fA79faF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBxhFarmBase(
            bxh,
            usdt,
            bxh_usdt_poolId,
            bxh_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [usdt, bxh];
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBxhUsdtLp";
    }
}
