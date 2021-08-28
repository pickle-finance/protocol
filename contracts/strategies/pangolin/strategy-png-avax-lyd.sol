// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxLydLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_lyd_lp_rewards = 0xE6dE666a80a357497A2cAB3A91F1c28dcAA1Eca4;
    address public png_avax_lyd_lp = 0x87B1Cf8f0Fd3e0243043642Cea7164a67Cb67E4d;
    address public lyd = 0x4C9B4E1AC6F24CdE3660D5E4Ef1eBF77C710C084;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            lyd,
            png_avax_lyd_lp_rewards,
            png_avax_lyd_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyPngAvaxLydLp";
    }
}
