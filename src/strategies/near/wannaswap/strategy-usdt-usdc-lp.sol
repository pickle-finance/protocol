// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-wanna-base.sol";

contract StrategyWannaUsdtUsdcLp is StrategyWannaFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public wanna_usdt_usdc_poolid = 3;
    // Token addresses
    address public wanna_usdt_usdc_lp =
        0x3502eaC6Fa27bEebDC5cd3615B7CB0784B0Ce48f;
    address public usdt = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;
    address public usdc = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyWannaFarmBase(
            usdt,
            usdc,
            wanna_usdt_usdc_poolid,
            wanna_usdt_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdt] = [wanna, usdt];
        swapRoutes[usdc] = [wanna, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyWannaUsdtUsdcLp";
    }
}
