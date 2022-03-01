// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-solarflare-farm-base.sol";

contract StrategyFlareGlmrEthLp is StrategyFlareFarmBase {
    uint256 public glmr_eth_poolId = 7;

    // Token addresses
    address public glmr_eth_lp = 0xb521C0aCf67390C1364f1e940e44dB25828E5Ef9;
    address public eth = 0xfA9343C3897324496A05fC75abeD6bAC29f8A40f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyFlareFarmBase(
            glmr_eth_lp,
            glmr_eth_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [flare, glmr, eth];
        swapRoutes[glmr] = [flare, glmr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFlareGlmrEthLp";
    }
}
