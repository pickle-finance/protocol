// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaUsdtBusdLp is StrategyCronaFarmBase {
    uint256 public usdt_busd_poolId = 7;

    // Token addresses
    address public usdt_busd_lp = 0x503d56B2f535784B7f2bcD6581F7e1b46DC0e60c;
    address public usdt = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address public busd = 0x6aB6d61428fde76768D7b45D8BFeec19c6eF91A8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            usdt,
            busd,
            usdt_busd_poolId,
            usdt_busd_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdt] = [crona, usdt];
        uniswapRoutes[busd] = [crona, usdt, busd];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaUsdtBusdLp";
    }
}
