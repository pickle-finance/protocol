// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-solarflare-farm-base.sol";

contract StrategyFlareGlmrMovrLp is StrategyFlareFarmBase {
    uint256 public glmr_movr_poolId = 9;

    // Token addresses
    address public glmr_movr_lp = 0xa65949fA1053903fcC019Ac21b0335aa4b4B1bFa;
    address public movr = 0x1d4C2a246311bB9f827F4C768e277FF5787B7D7E;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFlareFarmBase(
            glmr_movr_lp,
            glmr_movr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[movr] = [flare, glmr, movr];
        swapRoutes[glmr] = [flare, glmr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFlareGlmrMovrLp";
    }
}
