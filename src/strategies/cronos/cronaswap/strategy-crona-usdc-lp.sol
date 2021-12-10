// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-crona-farm-base.sol";

contract StrategyCronaCronaUsdcLp is StrategyCronaFarmBase {
    uint256 public crona_usdc_poolId = 6;

    // Token addresses
    address public crona_usdc_lp = 0x482E0eEb877091cfca439D131321bDE23ddf9bB5;
    address public usdc = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            crona,
            usdc,
            crona_usdc_poolId,
            crona_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[usdc] = [crona, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyCronaCronaUsdcLp";
    }
}
