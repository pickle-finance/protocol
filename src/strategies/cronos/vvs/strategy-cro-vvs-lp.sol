// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cronos-farm-base.sol";

contract StrategyCroVVSLp is StrategyVVSFarmBase {
    uint256 public cro_vvs_poolId = 4;

    // Token addresses
    address public cro_vvs_lp = 0xbf62c67eA509E86F07c8c69d0286C0636C50270b;
    address public vvs = 0x2D03bECE6747ADC00E1a131BBA1469C15fD11e03;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            cro,
            vvs,
            cro_vvs_poolId,
            cro_vvs_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        // uniswapRoutes[vvs] = [vvs, vvs];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroVVSLp";
    }
}
