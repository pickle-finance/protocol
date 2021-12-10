// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaBtcUsdcLp is StrategyCronaFarmBase {
    uint256 public btc_usdc_poolId = 23;

    // Token addresses
    address public btc_usdc_lp = 0xea7fc6A39B0d0344e1662E6ABF2FEcD19Bf3D029;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    address public btc = 0x062E66477Faf219F25D27dCED647BF57C3107d52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            btc,
            usdc,
            btc_usdc_poolId,
            btc_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [crona, usdc];
        uniswapRoutes[btc] = [crona, usdc, btc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaBtcUsdcLp";
    }
}
