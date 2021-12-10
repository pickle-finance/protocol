// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaUsdtCroLp is StrategyCronaFarmBase {
    uint256 public usdt_cro_poolId = 6;

    // Token addresses
    address public usdt_cro_lp = 0x968fE4C06fdD503E278d89d5dFe29935A111476C;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            usdt,
            cro,
            usdt_cro_poolId,
            usdt_cro_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [crona, usdt];
        uniswapRoutes[cro] = [crona, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaUsdtCroLp";
    }
}
