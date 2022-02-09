// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-lp-farm-base.sol";

contract StrategyOxdUsdcLp is StrategyOxdFarmBase {

    // Token addresses
    address public oxd_usdc_lp = 0xD5fa400a24EB2EA55BC5Bd29c989E70fbC626FfF;
    uint256 public oxd_usdc_poolId = 0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdFarmBase(
            oxd_usdc_lp,
            oxd_usdc_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[usdc] = [oxd, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdUsdcLp";
    }
}