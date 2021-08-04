// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxTrybLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_tryb_lp_rewards = 0x079a479e270E72A1899239570912358C6BC22d94;
    address public png_avax_tryb_lp = 0x6b41673fEff1bf0b55Ba2C9F4bf213b2bE8F474D;
    address public tryb = 0x564A341Df6C126f90cf3ECB92120FD7190ACb401;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            tryb,
            png_avax_tryb_lp_rewards,
            png_avax_tryb_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxTrybLp";
    }
}
