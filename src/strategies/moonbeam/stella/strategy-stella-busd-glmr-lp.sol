// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaBusdGlmrLp is StrategyStellaFarmBase {
    uint256 public busd_glmr_poolId = 8;

    // Token addresses
    address public busd_glmr_lp = 0x367c36dAE9ba198A4FEe295c22bC98cB72f77Fe1;
    address public busd = 0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            busd_glmr_lp,
            busd_glmr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [stella, glmr];
        swapRoutes[busd] = [stella, glmr, busd];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaBusdGlmrLp";
    }
}
