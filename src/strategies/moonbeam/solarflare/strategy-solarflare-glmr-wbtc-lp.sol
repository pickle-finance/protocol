// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-solarflare-farm-base.sol";

contract StrategyFlareGlmrWbtc is StrategyFlareFarmBase {
    uint256 public glmr_wbtc_poolId = 14;

    // Token addresses
    address public glmr_wbtc_lp = 0xDF74D67a4Fe29d9D5e0bfAaB3516c65b21a5d7cf;
    address public wbtc = 0x1DC78Acda13a8BC4408B207c9E48CDBc096D95e0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFlareFarmBase(
            glmr_wbtc_lp,
            glmr_wbtc_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[wbtc] = [flare, glmr, wbtc];
        swapRoutes[glmr] = [flare, glmr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFlareGlmrWbtc";
    }
}
