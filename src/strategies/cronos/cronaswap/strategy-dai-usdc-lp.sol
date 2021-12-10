// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaDaiUsdcLp is StrategyCronaFarmBase {
    uint256 public dai_usdc_poolId = 16;

    // Token addresses
    address public dai_usdc_lp = 0xaEbaFDbe975DB0bfbF4e95a6493CB93d02cc86aE;
    address public dai = 0xF2001B145b43032AAF5Ee2884e456CCd805F677D;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            dai,
            usdc,
            dai_usdc_poolId,
            dai_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[dai] = [crona, usdc, dai];
        uniswapRoutes[usdc] = [crona, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaDaiUsdcLp";
    }
}
