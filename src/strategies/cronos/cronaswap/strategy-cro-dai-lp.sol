// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCroDaiLp is StrategyCronaFarmBase {
    uint256 public cro_dai_poolId = 6;

    // Token addresses
    address public cro_dai_lp = 0xDA2FC0fE4B03deFf09Fd8CFb92d14e7ebC1F9690;
    address public dai = 0xF2001B145b43032AAF5Ee2884e456CCd805F677D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
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
        uniswapRoutes[cro] = [crona, cro];
        uniswapRoutes[dai] = [crona, cro, dai];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCroDaiLp";
    }
}
