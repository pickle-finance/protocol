// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyGlintUsdcBusdLp is StrategyGlintFarmBase {
    uint256 public usdc_busd_poolId = 2;

    // Token addresses
    address public usdc_busd_lp = 0xa0799832FB2b9F18Acf44B92FbbEDCfD6442DD5e;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;
    address public busd = 0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyGlintFarmBase(
            usdc_busd_lp,
            usdc_busd_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[busd] = [glint, glmr, busd];
        swapRoutes[usdc] = [glint, glmr, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyGlintUsdcBusdLp";
    }
}
