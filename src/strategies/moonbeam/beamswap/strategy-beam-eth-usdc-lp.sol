// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-beam-farm-base.sol";

contract StrategyGlintUsdcEthLp is StrategyGlintFarmBase {
    uint256 public usdc_eth_poolId = 4;

    // Token addresses
    address public usdc_eth_lp = 0x6BA3071760d46040FB4dc7B627C9f68efAca3000;
    address public usdc = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;
    address public eth = 0xfA9343C3897324496A05fC75abeD6bAC29f8A40f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyGlintFarmBase(
            usdc_eth_lp,
            usdc_eth_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[eth] = [glint, glmr, usdc, eth];
        swapRoutes[usdc] = [glint, glmr, usdc];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyGlintUsdcEthLp";
    }
}
