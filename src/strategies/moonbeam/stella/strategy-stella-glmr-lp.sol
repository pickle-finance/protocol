// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaGlmrLp is StrategyStellaFarmBase {
    uint256 public stella_glmr_poolId = 0;

    // Token addresses
    address public stella_glmr_lp = 0x7F5Ac0FC127bcf1eAf54E3cd01b00300a0861a62;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            stella_glmr_lp,
            stella_glmr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [stella, glmr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaGlmrLp";
    }
}
