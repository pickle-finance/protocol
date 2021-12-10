// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCronaCroLp is StrategyCronaFarmBase {
    uint256 public usdc_cro_poolId = 2;

    // Token addresses
    address public usdc_cro_lp = 0x0625A68D25d304aed698c806267a4e369e8Eb12a;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCronaFarmBase(
            usdc,
            cro,
            usdc_cro_poolId,
            usdc_cro_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[cro] = [crona, cro];
        uniswapRoutes[usdc] = [crona, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCronaCroLp";
    }
}
