// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvsnos-farm-base.sol";

contract StrategyVVSUsdcLp is StrategyVVSFarmBase {
    uint256 public vvs_usdc_poolId = 5;

    // Token addresses
    address public vvs_usdc_lp = 0x814920D1b8007207db6cB5a2dD92bF0b082BDBa1;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    address public vvs = 0x2D03bECE6747ADC00E1a131BBA1469C15fD11e03;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            vvs,
            usdc,
            vvs_usdc_poolId,
            vvs_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [vvs, usdc];
        // uniswapRoutes[vvs] = [vvs, vvs];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVVSUsdcLp";
    }
}
