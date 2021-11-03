// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-jswap-farm-base.sol";

contract StrategyJswapEthkUsdtLp is StrategyJswapFarmBase {
    uint256 public ethk_usdt_poolId = 1;

    // Token addresses
    address public jswap_ethk_usdt_lp = 0xeB02a695126B998E625394E43dfd26ca4a75CE2b;
    address public ethk = 0xEF71CA2EE68F45B9Ad6F72fbdb33d707b872315C;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJswapFarmBase(
            usdt,
            ethk,
            ethk_usdt_poolId,
            jswap_ethk_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [jswap, usdt];
        uniswapRoutes[ethk] = [jswap, usdt, ethk];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJswapEthkUsdtLp";
    }
}
