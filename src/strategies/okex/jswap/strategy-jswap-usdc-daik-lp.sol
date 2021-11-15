// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-jswap-farm-base.sol";

contract StrategyJswapUsdcDaikLp is StrategyJswapFarmBase {
    uint256 public usdc_daik_poolId = 42;

    // Token addresses
    address public jswap_usdc_daik_lp = 0xa25E1C05c58EDE088159cc3cD24f49445d0BE4b2;
    address public usdc = 0xc946DAf81b08146B1C7A8Da2A851Ddf2B3EAaf85;
    address public daik = 0x21cDE7E32a6CAF4742d00d44B07279e7596d26B9;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyJswapFarmBase(
            usdc,
            daik,
            usdc_daik_poolId,
            jswap_usdc_daik_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[daik] = [jswap, usdt, daik];
        uniswapRoutes[usdc] = [jswap, usdt, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyJswapUsdcDaikLp";
    }
}
