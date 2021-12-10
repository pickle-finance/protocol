// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaDaiCroLp is StrategyCronaFarmBase {
    uint256 public dai_cro_poolId = 6;

    // Token addresses
    address public dai_cro_lp = 0xDA2FC0fE4B03deFf09Fd8CFb92d14e7ebC1F9690;
    address public dai = 0xF2001B145b43032AAF5Ee2884e456CCd805F677D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            dai,
            cro,
            dai_cro_poolId,
            dai_cro_lp,
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
        return "StrategyCronaDaiCroLp";
    }
}
