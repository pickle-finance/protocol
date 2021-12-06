// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cronos-farm-base.sol";

contract StrategyCroBifiLp is StrategyVVSFarmBase {
    uint256 public cro_bifi_poolId = 11;

    // Token addresses
    address public cro_bifi_lp = 0x1803E360393A472beC6E1A688BDF7048d3076b1A;
    address public bifi = 0xe6801928061CDbE32AC5AD0634427E140EFd05F9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            cro,
            bifi,
            cro_bifi_poolId,
            cro_bifi_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[bifi] = [vvs, cro, bifi];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroBifiLp";
    }
}
