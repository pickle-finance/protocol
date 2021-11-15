// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-jswap-farm-base.sol";

contract StrategyJswapDaikUsdtLp is StrategyJswapFarmBase {
    uint256 public daik_usdt_poolId = 29;

    // Token addresses
    address public jswap_daik_usdt_lp = 0xE9313b7dea9cbaBd2df710C25bef44A748Ab38a9;
    address public daik = 0x21cDE7E32a6CAF4742d00d44B07279e7596d26B9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJswapFarmBase(
            usdt,
            daik,
            daik_usdt_poolId,
            jswap_daik_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [jswap, usdt];
        uniswapRoutes[daik] = [jswap, usdt, daik];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJswapDaikUsdtLp";
    }
}
