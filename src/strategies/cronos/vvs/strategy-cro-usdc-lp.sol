// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyCroUsdcLp is StrategyVVSFarmBase {
    uint256 public cro_usdc_poolId = 3;

    // Token addresses
    address public cro_usdc_lp = 0xe61Db569E231B3f5530168Aa2C9D50246525b6d6;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            cro,
            usdc,
            cro_usdc_poolId,
            cro_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [vvs, usdc];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroUsdcLp";
    }
}
