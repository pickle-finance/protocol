// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-png-farm-base.sol";

contract StrategyPngAvaxCnrLp is StrategyPngFarmBase {
    // Token addresses
    address public png_avax_cnr_lp_rewards =
        0xd43035F5Ef932E1335A664c707d85c54C924667e;
    address public png_avax_cnr_lp = 0xC04dE3796716ae5A6788b75DC0d4a1ecE06092d9;
    address public cnr = 0x8D88e48465F30Acfb8daC0b3E35c9D6D7d36abaf;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngFarmBase(
            cnr,
            png_avax_cnr_lp_rewards,
            png_avax_cnr_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxCnrLp";
    }
}
