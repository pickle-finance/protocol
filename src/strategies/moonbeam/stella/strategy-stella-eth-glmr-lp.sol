// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-stella-farm-base.sol";

contract StrategyStellaEthGlmrLp is StrategyStellaFarmBase {
    uint256 public eth_glmr_poolId = 7;

    // Token addresses
    address public eth_glmr_lp = 0x49a1cC58dCf28D0139dAEa9c18A3ca23108E78B3;
    address public eth = 0xfA9343C3897324496A05fC75abeD6bAC29f8A40f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStellaFarmBase(
            eth_glmr_lp,
            eth_glmr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[glmr] = [stella, glmr];
        swapRoutes[eth] = [stella, glmr, eth];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyStellaEthGlmrLp";
    }
}
