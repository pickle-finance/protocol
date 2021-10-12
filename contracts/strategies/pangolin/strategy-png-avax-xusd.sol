// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxXUsdLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_xusd_lp_rewards =
        0xbD56b964FCdd208a7a83C291864eEb8271BaB773;
    address public png_avax_xusd_lp =
        0xED84FEDb633D0523de53d46C8C99CbaE1f89D3b0;
    address public xusd = 0x3509f19581aFEDEff07c53592bc0Ca84e4855475;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            xusd,
            png_avax_xusd_lp_rewards,
            png_avax_xusd_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxXUsdLp";
    }
}
