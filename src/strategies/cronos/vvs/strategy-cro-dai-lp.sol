// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-cronos-farm-base.sol";

contract StrategyCroDaiLp is StrategyVVSFarmBase {
    uint256 public cro_dai_poolId = 10;

    // Token addresses
    address public cro_dai_lp = 0x3Eb9FF92e19b73235A393000C176c8bb150F1B20;
    address public dai = 0xF2001B145b43032AAF5Ee2884e456CCd805F677D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategySolarFarmBase(
            cro,
            dai,
            cro_dai_poolId,
            cro_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[dai] = [vvs, cro, dai];
        uniswapRoutes[cro] = [vvs, cro];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCroDaiLp";
    }
}
