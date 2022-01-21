// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyGlintGlintGlmrLp is StrategyGlintFarmBase {
    uint256 public glint_glmr_poolId = 0;

    // Token addresses
    address public glint_glmr_lp = 0x99588867e817023162F4d4829995299054a5fC57;
    address public glint = 0xcd3B51D98478D53F4515A306bE565c6EebeF1D58;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyGlintFarmBase(
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
        return "StrategyGlintGlintGlmrLp";
    }
}
