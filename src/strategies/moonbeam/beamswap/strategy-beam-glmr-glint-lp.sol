// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-beam-farm-base.sol";

contract StrategyGlintGlmrLp is StrategyBeamFarmBase {
    uint256 public glint_glmr_poolId = 0;

    // Token addresses
    address public glint_glmr_lp = 0x99588867e817023162F4d4829995299054a5fC57;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBeamFarmBase(
            glint_glmr_lp,
            glint_glmr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [glint, glmr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyGlintGlmrLp";
    }
}
