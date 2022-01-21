// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyGlintBusdGlmrLp is StrategyGlintFarmBase {
    uint256 public busd_glmr_poolId = 6;

    // Token addresses
    address public busd_glmr_lp = 0xfC422EB0A2C7a99bAd330377497FD9798c9B1001;
    address public busd = 0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyGlintFarmBase(
            busd_glmr_lp,
            busd_glmr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [glint, glmr];
        swapRoutes[busd] = [glint, glmr, busd];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyGlintBusdGlmrLp";
    }
}
